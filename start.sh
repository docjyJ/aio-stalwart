#!/bin/sh

AIO_LOCK="/opt/stalwart-mail/aio.lock"
DATA_VERSION="0.9"

STW_CONFIG_FILE="/opt/stalwart-mail/config/config.toml"
AIO_CONFIG_FILE="/opt/stalwart-mail/config/nc-aio-config.toml"

set_key() {
  sed "/^$1\s*=\s*.*/d"
  echo "$1 = $2"
}

get_key() {
  grep "$2" "$1" | sed "s/$2\s*=\s*[\"']?(.*)[\"']?/\1/"
}

get_aio_config_bool() {
  value=$(get_key "$AIO_CONFIG_FILE" "$1")
  if [ "$value" = "false" ]; then
    echo "false"
  elif [ "$value" = "true" ]; then
    echo "true"
  else
    set_key "$1" "$2" <"$AIO_CONFIG_FILE" >"/tmp$AIO_CONFIG_FILE"
    mv -f "/tmp$AIO_CONFIG_FILE" "$AIO_CONFIG_FILE"
    echo "$2"
  fi
}

if [ ! -f "$STW_CONFIG_FILE" ]; then
  touch "$STW_CONFIG_FILE"
fi

if [ ! -f "$AIO_CONFIG_FILE" ]; then
  touch "$AIO_CONFIG_FILE"
fi

if [ "$(get_aio_config_bool 'skip-secure-check' 'false')" = "false" ] && [ -f "$AIO_LOCK" ]; then
    if [ "$DATA_VERSION" != "$(cat "$AIO_LOCK")" ]; then
        echo "Your data is in an old format."
        echo "Make a backup and see https://github.com/docjyJ/aio-stalwart#Upgrading"
        echo "To avoid any loss of data, Stalwart will not launch."
        exit 1
    fi
else
    echo "$DATA_VERSION" > "$AIO_LOCK"
fi



# See https://github.com/stalwartlabs/mail-server/blob/main/resources/config/config.toml

mail_binding_config() {
  set_key 'server.listener.smtp.bind' '"[::]:25"' | \
  set_key 'server.listener.smtp.protocol' '"smtp"' | \
  set_key 'server.listener.smtp.tls.implicit' 'false' | \
  set_key 'server.listener.submissions.bind' '"[::]:465"' | \
  set_key 'server.listener.submissions.protocol' '"smtp"' | \
  set_key 'server.listener.submissions.tls.implicit' 'true' | \
  set_key 'server.listener.imaps.bind' '"[::]:993"' | \
  set_key 'server.listener.imaps.protocol' '"imap"' | \
  set_key 'server.listener.imaps.tls.implicit' 'true'
}

if [ "$(get_aio_config_bool 'manage.binding.mail' 'true')" = "true" ]; then
  mail_binding_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

web_binding_config() {
  set_key 'server.listener.caddy-aio.bind' '"[::]:10003"' | \
  set_key 'server.listener.caddy-aio.protocol' '"http"' | \
  set_key 'server.listener.caddy-aio.tls.implicit' 'false'
}

if [ "$(get_aio_config_bool 'manage.binding.caddy-web' 'true')" = "true" ]; then
  web_binding_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

storage_config() {
  set_key 'store.rocksdb.type' '"rocksdb"' | \
  set_key 'store.rocksdb.path' '"/opt/stalwart-mail/data/rocksdb"' | \
  set_key 'store.rocksdb.compression' '"lz4"' | \
  set_key 'storage.data' '"rocksdb"' | \
  set_key 'storage.fts' '"rocksdb"' | \
  set_key 'storage.blob' '"rocksdb"' | \
  set_key 'storage.lookup' '"rocksdb"'
}

if [ "$(get_aio_config_bool 'manage.storage.data' 'true')" = "true" ]; then
  storage_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

directory_config() {
  set_key 'directory.internal.type' '"internal"' | \
  set_key 'directory.internal.store' '"rocksdb"' | \
  set_key 'storage.directory' '"internal"'
}

if [ "$(get_aio_config_bool 'manage.storage.directory' 'true')" = "true" ]; then
  directory_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

log_file_config() {
  set_key 'tracer.log.type' '"log"' | \
  set_key 'tracer.log.level' '"trace"' | \
  set_key 'tracer.log.path' '"/var/log"' | \
  set_key 'tracer.log.prefix' '"stalwart.log"' | \
  set_key 'tracer.log.rotate' '"daily"' | \
  set_key 'tracer.log.ansi' 'false' | \
  set_key 'tracer.log.enable' 'true'
}

if [ "$(get_aio_config_bool 'manage.log.file' 'true')" = "true" ]; then
  log_file_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

stdout_config() {
  set_key 'tracer.stdout.type' '"stdout"' | \
  set_key 'tracer.stdout.level' '"trace"' | \
  set_key 'tracer.stdout.ansi' 'false' | \
  set_key 'tracer.stdout.enable' 'true'
}

if [ "$(get_aio_config_bool 'manage.log.stdout' 'true')" = "true" ]; then
  stdout_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

admin_config() {
  set_key 'authentication.fallback-admin.user' '"admin"' | \
  set_key 'authentication.fallback-admin.secret' '"%{env:STALWART_USER_PASS}%"'
}

if [ "$(get_aio_config_bool 'manage.admin' 'true')" = "true" ]; then
  admin_config <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"
  mv -f "/tmp$STW_CONFIG_FILE" "$STW_CONFIG_FILE"
fi

certificate_config() {
  set_key 'certificate.caddy-aio.key' "\"%{file:$1}%\"" | \
  set_key 'certificate.caddy-aio.cert' "\"%{file:$2}%\"" | \
  set_key 'certificate.caddy-aio.default' 'true'
}

if [ "$(get_aio_config_bool 'manage.certificate' 'true')" = "true" ]; then
  AIO_PRIV="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key"
  AIO_PUB="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt"

  certificate_config "$AIO_PRIV" "$AIO_PUB" <"$STW_CONFIG_FILE" >"/tmp$STW_CONFIG_FILE"

  [ -f "$AIO_PRIV" ] && cp "$AIO_PRIV" "$CERT_PRIV"
  while ! [ -f "$CERT_PRIV" ]; do
      echo "Waiting for key to get created..."
      sleep 5
      [ -f "$AIO_PRIV" ] && cp "$AIO_PRIV" "$CERT_PRIV"
  done

  [ -f "$AIO_PUB" ] && cp "$AIO_PUB" "$CERT_PUP"
  while ! [ -f "$CERT_PUP" ]; do
      echo "Waiting for cert to get created..."
      sleep 5
      [ -f "$AIO_PUB" ] && cp "$AIO_PUB" "$CERT_PUP"
  done
fi

echo "Stalwart container started"

# See https://github.com/stalwartlabs/mail-server/blob/main/resources/docker/entrypoint.sh

exec /usr/local/bin/stalwart-mail --config /opt/stalwart-mail/etc/config.toml
