# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM stalwartlabs/mail-server:v0.9.0

COPY --chmod=664 config.toml /opt/stalwart-mail/etc/config.toml
COPY --chmod=775 start.sh /start.sh

EXPOSE 10003

ENTRYPOINT [ "/start.sh" ]
