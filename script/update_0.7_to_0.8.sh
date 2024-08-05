echo -e '\033[0;31m WARNING: Please go in your AIO interface and backup your data before running this script. \033[0m'
read -p "Are-you sure you want to continue? (y/n) " -n 1 -r
echo -e '\n'
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker stop nextcloud-aio-stalwart
  docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail -it --entrypoint /bin/bash stalwartlabs/mail-server:v0.7.3 -c 'stalwart-mail --config /opt/stalwart-mail/etc/config.toml --export /opt/stalwart-mail/export'
  docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail -it --entrypoint /bin/bash stalwartlabs/mail-server:v0.8.0 -c 'stalwart-mail --config /opt/stalwart-mail/etc/config.toml --import /opt/stalwart-mail/export && echo "0.8.0" > /opt/stalwart-mail/aio.lock'
fi
echo 'Finished'
