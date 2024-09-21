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
PASSWORD="password"

print_step "Build Docker Image"
docker container rm $STALWART -f
docker volume rm $STALWART $CADDY -f
docker build -t "$STALWART" .
echo "docker run --rm -v $STALWART:/opt/stalwart-mail -v $CADDY:/caddy:ro --env "NC_DOMAIN=$NC_DOMAIN" $STALWART stalwart-cli --help"


print_step "Generate prepare env"
docker run --rm -v $CADDY:/ssl --entrypoint /bin/mkdir $STALWART -p "/ssl/$SSL_PATH/"
docker run --rm -v $CADDY:/ssl --entrypoint /bin/openssl $STALWART req -x509 -noenc -subj "/C=AA/ST=A/O=A/CN=mail.$NC_DOMAIN" -keyout "/ssl/$SSL_PATH/mail.$NC_DOMAIN.key" -out "/ssl/$SSL_PATH/mail.$NC_DOMAIN.crt"

print_step "Run container"
docker run --rm -v $CADDY:/caddy:ro -v $STALWART:/opt/stalwart-mail \
    -e "NC_DOMAIN=$NC_DOMAIN" \
    -e "STALWART_USER_PASS=$PASSWORD" \
    --name $STALWART $STALWART &
STALWART_PID=$!
sleep 11

print_step "Test"
docker exec $STALWART stalwart-cli -u http://127.0.0.1:10003 -c "admin:$PASSWORD" server list-config | sort > out.txt

print_step "Remove volume"
docker container rm $STALWART -f
docker volume rm $STALWART $CADDY
tail --pid=$STALWART_PID -f /dev/null
