#!/bin/bash

echo "This script needs access to the docker socket, run it with a user that has the rights to access it."
echo "Source code: https://github.com/docjyJ/aio-stalwart/blob/main/scripts/update_0.8_to_0.9.sh"
echo -e "\033[0;31m | WARNING: \033[0m"
echo -e "\033[0;31m | - Please go in your AIO interface and backup your data before running this script. \033[0m"
echo -e "\033[0;31m | - Please never run any script from the internet without reading its contents first. \033[0m"
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo -e "\n"

if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [ "$(docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/bash stalwartlabs/mail-server:v0.8.5 -c 'cat /opt/stalwart-mail/aio.lock')" = "0.8.0" ]; then
    docker stop nextcloud-aio-stalwart
    docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/bash stalwartlabs/mail-server:v0.9.0 -c 'echo "0.9.0" > /opt/stalwart-mail/aio.lock'
  echo "Finished"
  else
    echo "Your data is in wrong format."
  fi
else
  echo "Operation cancelled."
fi



