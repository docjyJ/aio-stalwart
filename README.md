> [!WARNING]
> Stalwart and nextcloud community containers are solutions under development.
>
> Additionally, hosting your own mail server is one of the most difficult services to deploy.
> 
> I try my best to make this as simple as possible. This solution is quite stable (I use it for my cloud) but it is not enterprise quality.
> 
> If you have any suggestions, questions or want to report a bug, [open an issue](https://github.com/docjyj/aio-stalwart/issues)!

# Stalwart community container for Nextcloud All-in-one

This container is used in [Nextcloud All-in-one](https://github.com/nextcloud/all-in-one/tree/main/community-containers/stalwart) to provide a mail server.

Compared to a default Stalwart container, this container allows:
- Automatically configures a mail server and *(In progress) tutorials for actions need to be done manually and advanced feature*.
- Compatible with Nextcloud AIO backups.
- *(Planned) Synchronization of Nextcloud and Stalwart accounts.*

## Getting started

### Prerequisites

1. You will run this container on a server with a static IP address.
2. Make sure than port `25`, `465`, `993`, `4190` and `10003` are not used by another programme. (Use `sudo netstat -tulpn` to list all used ports).
3. You have deployed the [caddy community container](https://github.com/nextcloud/all-in-one/tree/main/community-containers/caddy) as reverse proxy. (Other solutions are possible, see: [Use your own reverse proxy](#use-your-own-reverse-proxy)).

### Installation

See [how to use community containers](https://github.com/nextcloud/all-in-one/tree/main/community-containers#how-to-use-this).

After installation on nextcloud go to `https://mail.$NC_DOMAIN/login` and login with the following credentials:
- Username: `admin`
- Password: get with the command `docker inspect nextcloud-aio-stalwart  | grep STALWART_USER_PASS`

Once connected, add a domain, configure your DNS zone and create your users.

## Advanced configuration

### Use your own reverse proxy

You need to redirect http (or https) traffic from `mail.$NC_DOMAIN` to port `10003` of the `nextcloud-aio-stalwart` container in `http`.

**Then add your own certificate.** See : [Use your own certificate](#use-your-own-certificate)

Example with `Caddyfile` syntax:
```caddyfile
https://mail.{$NC_DOMAIN}:443 {
    reverse_proxy http://{$STALWAER_HOSTNAME}:10003
}
```

### Use your own certificate

Please add a certificate in volume `nextcloud_aio_caddy` in this path:
- `$VOLUME_ROOT/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key`
- `$VOLUME_ROOT/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt`

If you're using caddy, you can mount the volume `nextcloud_aio_caddy` your caddy container and add this [storage global directive](https://caddyserver.com/docs/caddyfile/options#storage):
```caddyfile
{
    storage file_system {$VOLUME_ROOT}/caddy
}
```

## Upgrading
> [!NOTE]
> Unless the starting script tells you, you have no action to do to update.

See https://github.com/stalwartlabs/mail-server/blob/main/UPGRADING.md

During a major server update, this message will be displayed:

```
Your data is in an old format.
Make a backup and see https://github.com/docjyJ/aio-stalwart#Upgrading
To avoid any loss of data, Stalwart will not launch.
```

> [!CAUTION]
> Before each update don't forget to make a backup.

### Upgrading from 0.7.x to 0.8.x

Run the script [`update_0.7_to_0.8.sh`](https://github.com/docjyJ/aio-stalwart/blob/main/scripts/update_0.7_to_0.8.sh) to update the data.

Please before upgrading, do a backup of your data !

If you're using the root user to run docker, read the script before running it.

```bash
curl -s https://raw.githubusercontent.com/docjyJ/aio-stalwart/main/scripts/backup.sh | bash
```

### Upgrading from 0.8.x to 0.9.x

This migration does not require any action, but the organization of the database has changed.
Be vigilant about possible data loss.

To unlock the server blocked by the start script, run this command:
```bash
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/bash stalwartlabs/mail-server:v0.9.0 -c 'echo "0.9" > /opt/stalwart-mail/aio.lock'
```
