# From https://github.com/stalwartlabs/mail-server/blob/main/Dockerfile
FROM ghcr.io/stalwartlabs/stalwart:v0.15.5@sha256:1fc4fbcb2c81f7f4fbe290939720e469ce949afd937c1b3d1a40930b2c38bbaf

COPY --chmod=775 bin/* /usr/local/bin/

# Install curl for heathcheck, alongside cron and pyhton which are used for migration from v15 to v16; cron and pyhton can be removed once upgraded to v16
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl cron python3 python3-pip python3-requests python3-urllib3\
    && rm -rf /var/lib/apt/lists/*

# Install cronjobs for exporting configuration once a day. This will be then applied to the migrated v16 stalwart server
RUN echo "0 2 * * * root ENVIRONMENT export-settings" >> /etc/crontab

EXPOSE 10003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD bash /usr/local/bin/healthcheck

ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD ["/usr/local/bin/stalwart", "--config", "/opt/stalwart-mail/etc/config.toml"]

# Needed for Nextcloud AIO so that image cleanup can work. 
# Unfortunately, this needs to be set in the Dockerfile in order to work.
LABEL org.label-schema.vendor="Nextcloud"
