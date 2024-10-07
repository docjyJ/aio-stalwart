# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM stalwartlabs/mail-server:v0.10.2

COPY --chmod=775 entrypoint.sh /entrypoint.sh
COPY --chmod=775 healthcheck.sh /healthcheck.sh
COPY --chmod=775 webadmin.sh /webadmin.sh

RUN apt-get install  --no-install-recommends -y curl=7.88.1-10+deb12u7

EXPOSE 10003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD bash /healthcheck.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/usr/local/bin/stalwart-mail", "--config", "/opt/stalwart-mail/etc/config.toml"]
