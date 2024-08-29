# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM stalwartlabs/mail-server:v0.9.3

COPY --chmod=775 entrypoint.sh /entrypoint.sh

EXPOSE 10003

ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]
CMD ["/usr/local/bin/stalwart-mail", "--config", "/opt/stalwart-mail/etc/config.toml"]
