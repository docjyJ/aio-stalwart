#!/bin/bash

# Test data
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

# Get cert
CERT_DIR="/opt/aio-certs"
CERT_PRIV="$CERT_DIR/privkey.key"
CERT_PUP="$CERT_DIR/fullchain.crt"

mkdir -p $CERT_DIR
rm -f "$CERT_PRIV"
rm -f "$CERT_PUP"

AIO_PRIV="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key"
AIO_PUB="/caddy/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt"


[ -f "$AIO_PRIV" ] && cp "$AIO_PRIV" "$CERT_PRIV"
while ! [ -f "$CERT_PRIV" ]; do
    echo "Waiting for key to get created..."
    sleep 5
    [ -f "$AIO_PRIV" ] && cp "$AIO_PRIV" "$CERT_PRIV"
done

[ -f "$AIO_PUB" ] && cp "$AIO_PUB" "$CERT_PUP"
while ! [ -f $CERT_PUP ]; do
    echo "Waiting for cert to get created..."
    sleep 5
    [ -f "$AIO_PUB" ] && cp "$AIO_PUB" "$CERT_PUP"
done

echo "Stalwart container started"

# Run the normal entrypoint
/usr/local/bin/entrypoint.sh
