FROM rust:1.60 as build
FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef

# Empty rust project is created, and dependencies copied into that project
RUN USER=root cargo new --bin rust-web-server
WORKDIR /rust-web-server

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder 
COPY --from=planner /rust-web-server/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json

# Build application
COPY . .
RUN cargo build --release --bin /rust-web-server

# We do not need the Rust toolchain to run the binary!
FROM debian:buster-slim AS runtime
WORKDIR /rust-web-server
COPY --from=builder /rust-web-server/target/release/rust-web-server .

EXPOSE 8000

# Health Check to ensure Web app is running correctly
HEALTHCHECK CMD curl --fail http://localhost:8000/health || exit 1  

# Label the container to link it to the Repo
LABEL org.opencontainers.image.source="https://github.com/jake-fawcett/rust-web-server"

CMD ["./rust-web-server"]