# Build stalwart-cli first to bundle it with the server
FROM rust:latest AS builder
WORKDIR /app
RUN git clone https://github.com/stalwartlabs/cli.git && \
    cd cli && \
    git checkout v1.0.6 && \
    cargo build --release

# Build mail server docker container
# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM ghcr.io/stalwartlabs/stalwart:v0.16.5@sha256:c435a9b97526205dd0bc46245ae97b960cf4cd7a5f1e411f14f36a9d5fc6efdb

COPY --chmod=775 bin/* /usr/local/bin/
COPY --chmod=775 --from=builder /app/cli/target/release/stalwart-cli /usr/local/bin/

USER root

EXPOSE 10003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD bash /usr/local/bin/healthcheck

ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD ["/usr/local/bin/stalwart", "--config", "/opt/stalwart-mail/etc/config.json"]

# Needed for Nextcloud AIO so that image cleanup can work.
# Unfortunately, this needs to be set in the Dockerfile in order to work.
LABEL org.label-schema.vendor="Nextcloud"
