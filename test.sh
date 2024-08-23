#!/bin/bash

STEP_NB=5
STEP_I=0
print_step() {
  STEP_I=$((STEP_I+1))
  echo ""
  echo "=====[$STEP_I/$STEP_NB]====="
  echo "$3"
}


NC_DOMAIN="example.com"
CADDY="my_caddy_example_com"
STALWART="my_stalwart_example_com"
SSL_PATH="caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN"

print_step "Build Docker Image"
docker build -t "$STALWART" .
echo "docker run --rm -v $STALWART:/opt/stalwart-mail -v $CADDY:/caddy:ro --env "NC_DOMAIN=$NC_DOMAIN" $STALWART stalwart-cli --help"


print_step "Generate prepare env"
docker run --rm -v $CADDY:/ssl --entrypoint /bin/mkdir $STALWART -p "/ssl/$SSL_PATH/"
docker run --rm -v $CADDY:/ssl --entrypoint /bin/openssl $STALWART req -x509 -noenc -subj "/C=AA/ST=A/O=A/CN=mail.$NC_DOMAIN" -keyout "/ssl/$SSL_PATH/mail.$NC_DOMAIN.key" -out "/ssl/$SSL_PATH/mail.$NC_DOMAIN.crt"

print_step "Test 1"
docker run --rm -v $CADDY:/caddy:ro -v $STALWART:/opt/stalwart-mail --env "NC_DOMAIN=$NC_DOMAIN" $STALWART cat /opt/stalwart-mail/etc/config.toml

print_step "Test 2"
docker run --rm -v $CADDY:/caddy:ro -v $STALWART:/opt/stalwart-mail --env "NC_DOMAIN=$NC_DOMAIN" $STALWART cat /opt/stalwart-mail/etc/config.toml

print_step "Remove vollume"
docker volume rm $STALWART $CADDY
