#!/bin/sh

if [ -f '/opt/stalwart-mail/config/aio-config.env' ]; then
  cat > '/opt/stalwart-mail/config/aio-config.env' << EOF
ENSURE_WEB_PORT_CONFIG=ON
ENSURE_MAIL_PORT_CONFIG=ON
ENSURE_STORAGE_CONFIG=ON
ENSURE_DIRECTORY_CONFIG=ON
ENSURE_FILE_LOGGING_CONFIG=ON
ENSURE_CONSOLE_LOGGING_CONFIG=ON
ENSURE_FALLBACK_ADMIN_CONFIG
AUTO_CONFIG_TLS_CERT=ON
EOF
fi
. '/opt/stalwart-mail/config/aio-config.env'

if [ "$SECURE_DATA_AFTER_UPGRADE" != "OFF" ]; then
  AIO_LOCK="/opt/stalwart-mail/aio.lock"
  DATA_VERSION="0.9"
  if [ -f "$AIO_LOCK" ]; then
    if [ "$DATA_VERSION" != "$(cat "$AIO_LOCK")" ]; then
      echo "Your data is in an old format."
      echo "Make a backup and see https://github.com/docjyJ/aio-stalwart#Upgrading"
      echo "To avoid any loss of data, Stalwart will not launch."
    exit 1
    fi
  else
    echo "$DATA_VERSION" > "$AIO_LOCK"
  fi
fi

# See https://github.com/stalwartlabs/mail-server/blob/main/resources/config/config.toml

STW_CONFIG_FILE="/opt/stalwart-mail/config/config.toml"
echo >> "$STW_CONFIG_FILE"

if [ "$ENSURE_MAIL_PORT_CONFIG" != "OFF" ]; then
  sed -i '/^server\.listener\.aio-(smtp|submissions|imaps)\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
server.listener.aio-smtp.bind = "[::]:25"
server.listener.aio-smtp.protocol = "smtp"
server.listener.aio-submissions.bind = "[::]:465"
server.listener.aio-submissions.protocol = "smtp"
server.listener.aio-submissions.tls.implicit = true
server.listener.aio-imaps.bind = "[::]:993"
server.listener.aio-imaps.protocol = "imap"
server.listener.aio-imaps.tls.implicit = true
EOF
fi

if [ "$ENSURE_WEB_PORT_CONFIG" != "OFF" ]; then
  sed -i '/^server\.listener\.aio-caddy\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
server.listener.aio-caddy.bind = "[::]:10003"
server.listener.aio-caddy.protocol = "http"
EOF
fi

if [ "$ENSURE_STORAGE_CONFIG" != "OFF" ]; then
  sed -i '/^store\.aio-rocksdb\./d' "$STW_CONFIG_FILE"
  sed -i '/^storage\.(data|fts|blob|lookup)/d' "$STW_CONFIG_FILE"
cat >> "$STW_CONFIG_FILE" << EOF
store.aio-rocksdb.type = "rocksdb"
store.aio-rocksdb.path = "/opt/stalwart-mail/data/rocksdb"
store.aio-rocksdb.compression = "lz4"
storage.data = "aio-rocksdb"
storage.fts = "aio-rocksdb"
storage.blob = "aio-rocksdb"
storage.lookup = "aio-rocksdb"
EOF
fi

if [ "$ENSURE_DIRECTORY_CONFIG" != "OFF" ]; then
  sed -i '/^directory\.internal\./d' "$STW_CONFIG_FILE"
  sed -i '/^storage\.directory/d' "$STW_CONFIG_FILE"
cat >> "$STW_CONFIG_FILE" << EOF
directory.aio-rocksdb.type = "aio-rocksdb"
directory.aio-rocksdb.store = "aio-rocksdb"
storage.directory = "aio-rocksdb"
EOF
fi

if [ "$ENSURE_FILE_LOGGING_CONFIG" != "OFF" ]; then
  sed -i '/^tracer\.aio-log\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
tracer.aio-log.type = "log"
tracer.aio-log.level = "trace"
tracer.aio-log.path = "/var/log"
tracer.aio-log.prefix = "stalwart.log"
tracer.aio-log.rotate = "daily"
tracer.aio-log.ansi = false
tracer.aio-log.enable = true
EOF
fi

if [ "$ENSURE_CONSOLE_LOGGING_CONFIG" != "OFF" ]; then
  sed -i '/^tracer\.aio-stdout\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
tracer.aio-stdout.type = "stdout"
tracer.aio-stdout.level = "trace"
tracer.aio-stdout.ansi = false
tracer.aio-stdout.enable = true
EOF
fi

if [ "$ENSURE_FALLBACK_ADMIN_CONFIG" != "OFF" ]; then
  sed -i '/^authentication\.fallback-admin\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
authentication.fallback-admin.user = "admin"
authentication.fallback-admin.secret = "%{env:STALWART_USER_PASS}%"
EOF
fi

if [ "$AUTO_CONFIG_TLS_CERT" != "OFF" ]; then
  AIO_KEY="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key"
  AIO_PUB="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt"

  sed -i '/^certificate\.caddy-aio\./d' "$STW_CONFIG_FILE"
  cat >> "$STW_CONFIG_FILE" << EOF
certificate.caddy-aio.key = "%{file:$AIO_PRIV}%"
certificate.caddy-aio.cert = "%{file:$AIO_PUB}%"
certificate.caddy-aio.default = true
EOF

  while [ ! -f "$AIO_KEY" ] || [ ! -f "$AIO_PUB" ]; do
    echo "Waiting for cert to get created..."
    sleep 5
  done
fi

# See https://github.com/stalwartlabs/mail-server/blob/main/resources/docker/entrypoint.sh

echo "Stalwart initialization complete. Starting Stalwart..."

exec /usr/local/bin/stalwart-mail --config /opt/stalwart-mail/etc/config.toml
