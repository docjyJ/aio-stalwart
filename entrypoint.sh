#!/bin/bash

if [ ! -f '/opt/stalwart-mail/etc/aio-config.env' ]; then
  mkdir -p '/opt/stalwart-mail/etc'
  echo '## REMOVE VARIABLES BELOW IF YOU WANT TO USE DEFAULT VALUES ##' > '/opt/stalwart-mail/etc/aio-config.env'
else
  # shellcheck disable=SC1091
  source '/opt/stalwart-mail/etc/aio-config.env'
fi

STW_CONFIG_FILE="/opt/stalwart-mail/etc/config.toml"
STW_AIO_ENV="/opt/stalwart-mail/etc/aio-config.env"
AIO_LOCK="/opt/stalwart-mail/aio.lock"
DATA_VERSION="0.9"

if [ -z "$SECURE_DATA_AFTER_UPGRADE" ]; then
  echo 'SECURE_DATA_AFTER_UPGRADE="ON"' >> "$STW_AIO_ENV"
  SECURE_DATA_AFTER_UPGRADE="ON"
fi

if [ "$SECURE_DATA_AFTER_UPGRADE" != "OFF" ]; then
  if [ -f "$AIO_LOCK" ]; then
    if [ "$DATA_VERSION" != "$(cat "$AIO_LOCK")" ]; then
      >&2 echo 'Your data is in an old format.'
      >&2 echo 'Make a backup and see https://github.com/docjyJ/aio-stalwart#Upgrading'
      >&2 echo 'To avoid any loss of data, Stalwart will not launch.'
      exit 1
    fi
  else
    echo "$DATA_VERSION" > "$AIO_LOCK"
  fi
fi

# See https://github.com/stalwartlabs/mail-server/blob/main/resources/config/config.toml

function format_toml() {
  GROUP=''
  while IFS= read -r i || [ -n "$i" ]; do
    if [[ "$i" =~ ^[[:space:]]*\[[[:space:]]*(.+)[[:space:]]*\](.*)?[[:space:]]*$ ]]; then
      GROUP="${BASH_REMATCH[1]}."
    elif [[ "$i" =~ ^[[:space:]]*([^=#[:space:]]+)[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
      echo "$GROUP${BASH_REMATCH[1]} = ${BASH_REMATCH[2]}"
    fi
  done
}

function mail_port() {
  if [ -z "$ENSURE_MAIL_PORT_CONFIG" ]; then
    echo 'ENSURE_MAIL_PORT_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_MAIL_PORT_CONFIG="ON"
  fi

  if [ "$ENSURE_MAIL_PORT_CONFIG" = "ON" ]; then
    sed -e '/^server\.listener\.aio-mail/d'
    echo 'server.listener.aio-mail.bind = "[::]:25"'
    echo 'server.listener.aio-mail.protocol = "smtp"'
  else
    cat
  fi
}

function submission_port() {
  if [ -z "$ENSURE_SUBMISSION_PORT_CONFIG" ]; then
    echo 'ENSURE_SUBMISSION_PORT_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_SUBMISSION_PORT_CONFIG="ON"
  fi

  if [ "$ENSURE_SUBMISSION_PORT_CONFIG" = "ON" ]; then
    sed -e '/^server\.listener\.aio-submission/d'
    echo 'server.listener.aio-submission.bind = "[::]:587"'
    echo 'server.listener.aio-submission.protocol = "smtp"'
    echo 'server.listener.aio-submission.tls.implicit = true'
  else
    cat
  fi
}

function imap_port() {
  if [ -z "$ENSURE_IMAP_PORT_CONFIG" ]; then
    echo 'ENSURE_IMAP_PORT_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_IMAP_PORT_CONFIG="ON"
  fi

  if [ "$ENSURE_IMAP_PORT_CONFIG" = "ON" ]; then
    sed -e '/^server\.listener\.aio-imap/d'
    echo 'server.listener.aio-imap.bind = "[::]:993"'
    echo 'server.listener.aio-imap.protocol = "imap"'
    echo 'server.listener.aio-imap.tls.implicit = true'
  else
    cat
  fi
}

#function pop3_port() {
#  if [ -z "$ENSURE_POP3_PORT_CONFIG" ]; then
#    echo 'ENSURE_POP3_PORT_CONFIG="OFF"' >> "$STW_AIO_ENV"
#    ENSURE_POP3_PORT_CONFIG="OFF"
#  fi
#
#  if [ "$ENSURE_POP3_PORT_CONFIG" = "ON" ]; then
#    sed -e '/^server\.listener\.aio-pop3/d'
#    echo 'server.listener.aio-pop3.bind = "[::]:995"'
#    echo 'server.listener.aio-pop3.protocol = "pop3"'
#    echo 'server.listener.aio-pop3.tls.implicit = true'
#  else
#    cat
#  fi
#}

function web_port() {
  if [ -z "$ENSURE_WEB_PORT_CONFIG" ]; then
    echo 'ENSURE_WEB_PORT_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_WEB_PORT_CONFIG="ON"
  fi

  if [ "$ENSURE_WEB_PORT_CONFIG" = "ON" ]; then
    sed -e '/^server\.listener\.aio-caddy\./d'
    echo 'server.listener.aio-caddy.bind = "[::]:10003"'
    echo 'server.listener.aio-caddy.protocol = "http"'
  else
    cat
  fi
}

function managesieve_port() {
  if [ -z "$ENSURE_MANAGESIEVE_PORT_CONFIG" ]; then
    echo 'ENSURE_MANAGESIEVE_PORT_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_MANAGESIEVE_PORT_CONFIG="ON"
  fi

  if [ "$ENSURE_MANAGESIEVE_PORT_CONFIG" != "OFF" ]; then
    sed -e '/^server\.listener\.aio-managesieve/d'
    echo 'server.listener.aio-managesieve.bind = "[::]:4190"'
    echo 'server.listener.aio-managesieve.protocol = "managesieve"'
    echo 'server.listener.aio-managesieve.tls.implicit = true'
  else
    cat
  fi
}

function storage() {
  if [ -z "$ENSURE_STORAGE_CONFIG" ]; then
    echo 'ENSURE_STORAGE_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_STORAGE_CONFIG="ON"
  fi

  if [ "$ENSURE_STORAGE_CONFIG" = "ON" ]; then
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

function directory() {
  if [ -z "$ENSURE_DIRECTORY_CONFIG" ]; then
    echo 'ENSURE_DIRECTORY_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_DIRECTORY_CONFIG="ON"
  fi

  if [ "$ENSURE_DIRECTORY_CONFIG" = "ON" ]; then
    sed -e '/^directory\.internal\./d' -e '/^storage\.directory/d'
    echo 'directory.aio-rocksdb.type = "aio-rocksdb"'
    echo 'directory.aio-rocksdb.store = "aio-rocksdb"'
    echo 'storage.directory = "aio-rocksdb"'
  else
    cat
  fi
}

function file_logging() {
  if [ -z "$ENSURE_FILE_LOGGING_CONFIG" ]; then
    echo 'ENSURE_FILE_LOGGING_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_FILE_LOGGING_CONFIG="ON"
  fi

  if [ "$ENSURE_FILE_LOGGING_CONFIG" = "ON" ]; then
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

function console_logging() {
  if [ -z "$ENSURE_CONSOLE_LOGGING_CONFIG" ]; then
    echo 'ENSURE_CONSOLE_LOGGING_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_CONSOLE_LOGGING_CONFIG="ON"
  fi

  if [ "$ENSURE_CONSOLE_LOGGING_CONFIG" = "ON" ]; then
    sed -e '/^tracer\.aio-stdout\./d'
    echo 'tracer.aio-stdout.type = "stdout"'
    echo 'tracer.aio-stdout.level = "trace"'
    echo 'tracer.aio-stdout.ansi = false'
    echo 'tracer.aio-stdout.enable = true'
  else
    cat
  fi
}

function fallback_admin() {
  if [ -z "$ENSURE_FALLBACK_ADMIN_CONFIG" ]; then
    echo 'ENSURE_FALLBACK_ADMIN_CONFIG="ON"' >> "$STW_AIO_ENV"
    ENSURE_FALLBACK_ADMIN_CONFIG="ON"
  fi

  if [ "$ENSURE_FALLBACK_ADMIN_CONFIG" = "ON" ]; then
    sed -e '/^authentication\.fallback-admin\./d'
    echo 'authentication.fallback-admin.user = "admin"'
    echo 'authentication.fallback-admin.secret = "%{env:STALWART_USER_PASS}%"'
  else
    cat
  fi
}

function auto_config_cert() {
  if [ -z "$AUTO_CONFIG_TLS_CERT" ]; then
    echo 'AUTO_CONFIG_TLS_CERT="ON"' >> "$STW_AIO_ENV"
    AUTO_CONFIG_TLS_CERT="ON"
  fi

  if [ "$AUTO_CONFIG_TLS_CERT" = "ON" ]; then
    if [ -z "$NC_DOMAIN" ]; then
      >&2 echo "NC_DOMAIN is not set."
      cat > /dev/null
    else
      AIO_KEY="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key"
      AIO_PUB="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt"

      sed -e '/^certificate\.caddy-aio\./d'
      echo "certificate.caddy-aio.key = \"%{file:$AIO_KEY}%\""
      echo "certificate.caddy-aio.cert = \"%{file:$AIO_PUB}%\""

      while [ ! -f "$AIO_KEY" ] || [ ! -f "$AIO_PUB" ]; do
        >&2 echo "Waiting for cert to get created..."
        sleep 5
      done
    fi
  else
    cat
  fi
}

if [ -f "$STW_CONFIG_FILE" ]; then
  mv "$STW_CONFIG_FILE" "$STW_CONFIG_FILE.old"
else
  touch "$STW_CONFIG_FILE.old"
fi

format_toml < "$STW_CONFIG_FILE.old" | \
  mail_port | \
  submission_port | \
  imap_port | \
  web_port | \
  managesieve_port | \
  storage | \
  directory | \
  file_logging | \
  console_logging | \
  fallback_admin | \
  auto_config_cert | \
  sort > "$STW_CONFIG_FILE"

if [ ! -s "$STW_CONFIG_FILE" ]; then
  rm "$STW_CONFIG_FILE"
  >&2 echo "Failed to generate config file."
  exit 1
fi

echo "Stalwart initialization complete. Starting Stalwart..."

exec "$@"
