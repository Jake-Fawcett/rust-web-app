FROM rust:1.60 as build

# Empty rust project is created, and dependencies copied into that project
RUN USER=root cargo new --bin rust-web-app
WORKDIR /rust-web-app
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

RUN apt-get install -y cmake

# Release build is triggered, then src folder removed
# This means if src is changed, dependencies do not need to be rebuilt
RUN cargo build --release
RUN rm src/*.rs
COPY ./src ./src

# Remove dependency binary and trigger another release build with everything
RUN rm ./target/release/deps/rust_web_app*
RUN cargo build --release

FROM debian:buster-slim
COPY --from=build /rust-web-app/target/release/rust-web-app .

EXPOSE 8000

CMD ["./rust-web-app"]