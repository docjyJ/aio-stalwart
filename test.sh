#!/bin/bash

# NOTE: This script use podman instead of docker !

podman build . -t stalwart-mail-test
podman run --rm -p 10003:10003 stalwart-mail-test
