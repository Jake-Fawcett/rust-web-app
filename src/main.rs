use askama::Template;
use axum::{
    response::{Html, IntoResponse, Response},
    routing::get, 
    Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    // build our application with a route
    let app = Router::new()
        .route("/", get(hello_handler))
        .route("/health", get(health_handler))
        .route("/hello/:name", get(hello));

    // run it
    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    println!("listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn main_handler() -> impl IntoResponse {
    println!("/ called");
    let template = MainTemplate;
    HtmlTemplate(template)
}

async fn health_handler() -> impl IntoResponse {
    println!("/health called");
    let template = HealthTemplate;
    HtmlTemplate(template)
}

async fn hello_handler(extract::Path(name): extract::Path<String>) -> impl IntoResponse {
    println_f!("/hello/{name} called");
    let template = HelloTemplate { name };
    HtmlTemplate(template)
}


#[derive(Template)]
#[template(path = "main.html")]
struct MainTemplate {
}

#[derive(Template)]
#[template(path = "health.html")]
struct HealthTemplate {
}

#[derive(Template)]
#[template(path = "hello.html")]
struct HelloTemplate {
    name: String,
}

struct HtmlTemplate<T>(T);

impl<T> IntoResponse for HtmlTemplate<T>
where
    T: Template,
{
    fn into_response(self) -> Response {
        match self.0.render() {
            Ok(html) => Html(html).into_response(),
            Err(err) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Failed to render template. Error: {}", err),
            )
                .into_response(),
        }
    }
}