FROM rust:1.60 as build

# Empty rust project is created, and dependencies copied into that project
RUN USER=root cargo new --bin rust-web-server
WORKDIR /rust-web-server
COPY ./.cargo ./.cargo
COPY ./Cargo.toml ./Cargo.toml
COPY ./Cargo.lock ./Cargo.lock


RUN apt-get update && apt-get install -y cmake

# Release build is triggered, then src folder removed
# This means if src is changed, dependencies do not need to be rebuilt
RUN cargo build --release
RUN rm src/*.rs
COPY ./src ./src
COPY ./templates ./templates

# Remove dependency binary and trigger another release build with everything
RUN rm ./target/release/deps/rust_web_server*
RUN cargo build --release

FROM debian:buster-slim
COPY --from=build /rust-web-server/target/release/rust-web-server .

EXPOSE 8000

# Label the container to link it to the Repo
LABEL org.opencontainers.image.source="https://github.com/jake-fawcett/rust-web-server"

CMD ["./rust-web-server"]