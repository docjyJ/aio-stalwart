#!/bin/bash

# NOTE: This script use podman instead of docker !
docker() {
  podman "$@"
}

#
# Work in progress
#

IMAGE=$(docker build . | tee /dev/tty | tail -n 1)

echo "Script generated :"

docker run --rm --env AUTO_CONFIG_TLS_CERT=OFF  "$IMAGE" cat /opt/stalwart-mail/etc/config.toml
