#!/bin/bash

# NOTE: This script use podman instead of docker !
docker() {
  podman "$@"
}

STEP_NB=3
STEP_I=0
print_step() {
  STEP_I=$((STEP_I+1))
  echo ""
  echo "=====[$STEP_I/$STEP_NB]====="
  echo "$3"
}


print_step "Build Docker Image"
IMAGE=$(docker build . | tee /dev/tty | tail -n 1)

print_step "Generate prepare env"
NC_DOMAIN="example.com"
CADDY="my_caddy_example_com"
STALWART="my_stalwart_example_com"
docker run --rm -v $V_CADDY:/data caddy caddy reverse-proxy -i -f https://mail.example.com -t http://$STALWART:10003

print_step "Test 1"
docker run --rm --env AUTO_CONFIG_TLS_CERT=OFF  "$IMAGE" cat /opt/stalwart-mail/etc/config.toml
