# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM stalwartlabs/mail-server:v0.8.2

COPY --chmod=664 config.toml /opt/stalwart-mail/etc/config.toml
COPY --chmod=775 start.sh /start.sh

ENTRYPOINT [ "/start.sh" ]
