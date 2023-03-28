use askama::Template;
use axum::{
    response::{Html, IntoResponse, Response},
    http::StatusCode,
    routing::get, 
    extract,
    Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    // Build the application with a route
    let app = Router::new()
        .route("/", get(index_handler))
        .route("/health", get(health_handler))
        .route("/hello/:name", get(hello_handler));

    // Run the application
    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    println!("listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn index_handler() -> impl IntoResponse {
    println!("/ called");
    let template = IndexTemplate {}; // Instantiate Struct
    HtmlTemplate(template) // Render Struct
}

async fn health_handler() -> impl IntoResponse {
    println!("/health called");
    let template = HealthTemplate {};
    HtmlTemplate(template)
}

async fn hello_handler(extract::Path(name): extract::Path<String>) -> impl IntoResponse {
    println!("/hello/{} called", name);
    let template = HelloTemplate { name };
    HtmlTemplate(template)
}


#[derive(Template)] // Askama generated the code..
#[template(path = "index.html")] // using the template in the below path relative to templates
struct IndexTemplate {}

#[derive(Template)]
#[template(path = "health.html")]
struct HealthTemplate {}

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