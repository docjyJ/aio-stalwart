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

format_toml() {
  GROUP=''
  REG_GROUP='^ *\[ *(.+) *\]( *#.+)?\s*$'
  REG_ITEM='^ *([^=# ]+) *= *(.+)\s*$'
  while read i || [ -n "$i" ]; do
    if [[ $i =~ $REG_GROUP ]]; then
      GROUP="$(echo "$i" | sed -r "s/$REG_GROUP/\1./g")"
    elif [[ $i =~ $REG_ITEM ]]; then
      echo "$GROUP$(echo "$i" | sed -r "s/$REG_ITEM/\1 = \2/g")"
    fi
  done
}

mail_ports() {
  if [ "$ENSURE_MAILS_PORT_CONFIG" != "OFF" ]; then
    sed -e '/^server\.listener\.aio-smtp/d' -e '/^server\.listener\.aio-submissions/d' -e '/^server\.listener\.aio-imaps/d'
    echo 'server.listener.aio-smtp.bind = "[::]:25"'
    echo 'server.listener.aio-smtp.protocol = "smtp"'
    echo 'server.listener.aio-submissions.bind = "[::]:465"'
    echo 'server.listener.aio-submissions.protocol = "smtp"'
    echo 'server.listener.aio-submissions.tls.implicit = true'
    echo 'server.listener.aio-imaps.bind = "[::]:993"'
    echo 'server.listener.aio-imaps.protocol = "imap"'
    echo 'server.listener.aio-imaps.tls.implicit = true'
  else
    cat
  fi
}

web_port() {
  if [ "$ENSURE_WEB_PORT_CONFIG" != "OFF" ]; then
    sed -e '/^server\.listener\.aio-caddy\./d'
    echo 'server.listener.aio-caddy.bind = "[::]:10003"'
    echo 'server.listener.aio-caddy.protocol = "http"'
  else
    cat
  fi
}

storage_port() {
  if [ "$ENSURE_STORAGE_CONFIG" != "OFF" ]; then
    sed -e '/^store\.aio-rocksdb\./d' -e '/^storage\.data/d' -e '/^storage\.fts/d' -e '/^storage\.blob/d' -e '/^storage\.lookup/d'
    echo 'store.aio-rocksdb.type = "rocksdb"'
    echo 'store.aio-rocksdb.path = "/opt/stalwart-mail/data/rocksdb"'
    echo 'store.aio-rocksdb.compression = "lz4"'
    echo 'storage.data = "aio-rocksdb"'
    echo 'storage.fts = "aio-rocksdb"'
    echo 'storage.blob = "aio-rocksdb"'
    echo 'storage.lookup = "aio-rocksdb"'
  else
    cat
  fi
}

directory() {
  if [ "$ENSURE_DIRECTORY_CONFIG" != "OFF" ]; then
    sed -e '/^directory\.internal\./d' -e '/^storage\.directory/d'
    echo 'directory.aio-rocksdb.type = "aio-rocksdb"'
    echo 'directory.aio-rocksdb.store = "aio-rocksdb"'
    echo 'storage.directory = "aio-rocksdb"'
  else
    cat
  fi
}

file_logging() {
  if [ "$ENSURE_FILE_LOGGING_CONFIG" != "OFF" ]; then
    sed -e '/^tracer\.aio-log\./d'
    echo 'tracer.aio-log.type = "log"'
    echo 'tracer.aio-log.level = "trace"'
    echo 'tracer.aio-log.path = "/var/log"'
    echo 'tracer.aio-log.prefix = "stalwart.log"'
    echo 'tracer.aio-log.rotate = "daily"'
    echo 'tracer.aio-log.ansi = false'
    echo 'tracer.aio-log.enable = true'
  else
    cat
  fi
}

console_logging() {
  if [ "$ENSURE_CONSOLE_LOGGING_CONFIG" != "OFF" ]; then
    sed -e '/^tracer\.aio-stdout\./d'
    echo 'tracer.aio-stdout.type = "stdout"'
    echo 'tracer.aio-stdout.level = "trace"'
    echo 'tracer.aio-stdout.ansi = false'
    echo 'tracer.aio-stdout.enable = true'
  else
    cat
  fi
}

fallback_admin() {
  if [ "$ENSURE_FALLBACK_ADMIN_CONFIG" != "OFF" ]; then
    sed -e '/^authentication\.fallback-admin\./d'
    echo 'authentication.fallback-admin.user = "admin"'
    echo 'authentication.fallback-admin.secret = "%{env:STALWART_USER_PASS}%"'
  else
    cat
  fi
}

STW_CONFIG_FILE="/opt/stalwart-mail/config/config.toml"

cat "$STW_CONFIG_FILE" > "$STW_CONFIG_FILE.log"
cat "$STW_CONFIG_FILE.log" | format_toml | mail_ports | web_port | storage_port | directory | file_logging | console_logging | fallback_admin | sort > "$STW_CONFIG_FILE"


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
