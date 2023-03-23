use axum::{response::Html, routing::get, Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    // build our application with a route
    let app = Router::new()
        .route("/", get(hello_handler))
        .route("/health", get(health_handler));

    // run it
    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    println!("listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn hello_handler() -> Html<&'static str> {
    println!("/ called");
    Html("<h1>Hello, World!</h1>")
}

async fn health_handler() -> &'static str {
    println!("/health called");
    "Healthy"
}