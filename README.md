> [!CAUTION]
> Do not use this feature as a main mail server, without a redundancy system and without knowledge.
 
> [!WARNING]
> Stalwart and nextcloud community containers are solutions under development.
>
> Additionally, be aware that the mail server is the most difficult service to deploy.
> 
> I try my best to make this as simple as possible. This solution is quite stable (I use it for my cloud) but it is not enterprise quality.
> 
> If you have any suggestions, questions or want to report a bug, [open an issue](https://github.com/docjyj/aio-stalwart/issues)!

# Stalwart community container for Nextcloud All-in-one

This container is used in [Nextcloud All-in-one](https://github.com/nextcloud/all-in-one/tree/main/community-containers/stalwart) to provide a mail server.

This container works with the [caddy community container](https://github.com/nextcloud/all-in-one/tree/main/community-containers/caddy) as reverse proxy.

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

Additionally, you might want to install and configure [snappymail](https://apps.nextcloud.com/apps/snappymail) or [mail](https://apps.nextcloud.com/apps/mail) inside Nextcloud in order to use your mail accounts for sending and retrieving mails.

## Advanced configuration

> [!IMPORTANT]
> This image overrides the configuration of the Stalwart on every start.
> 
> This prevents you from making changes that break links with Nextcloud and the Caddy Community Container.

See the [Stalwart FAQ](https://stalw.art/docs/faq) to see all possibilities.

For any question [open an issue](https://github.com/docjyj/aio-stalwart/issues)!

### Change the admin password

Before changing the password, make sure to disable the automatic configuration of the fallback admin. See [Options](#options).

Then you can remove or change the password in the web-admin.


### Use a custom domain

You can use a custom domain for the mail server.

1. To do this, you need to disable the automatic configuration of certificates. See [Options](#options).
2. Then, configure your own reverse proxy. See [Use your own reverse proxy](#use-your-own-reverse-proxy).
3. Finally, add your own certificate. See [Stalwart Certificate](https://stalw.art/docs/server/tls/certificates).


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

If you're using another domain. Please disable the automatic configuration of certificates. See [Options](#options) and [Stalwart Certificate](https://stalw.art/docs/server/tls/certificates).

## Options

You can disable somme automatic override configuration with environment variables in the file `/opt/stalwart-mail/etc/aio-config.env`.

| Variable                         | Description                                                                                                                               | Default | WebAdmin url                                                     |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------|------------------------------------------------------------------|
| `SECURE_DATA_AFTER_UPGRADE`      | Prevent the server from starting if the data is in an old format.                                                                         | `ON`    |                                                                  |
| `ENSURE_MAIL_PORT_CONFIG`        | Force mail exchange port configuration.<br/>This port is used to receive emails.                                                          | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-mail/edit`        |
| `ENSURE_SUBMISSION_PORT_CONFIG`  | Force mail submission port configuration.<br/>This port is used to send emails.                                                           | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-submission/edit`  |
| `ENSURE_IMAP_PORT_CONFIG`        | Force IMAP port configuration.<br/>This port is used to read emails.                                                                      | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-imap/edit`        |
| `ENSURE_WEB_PORT_CONFIG`         | Force web port configuration.<br/>This port is used to access the web-admin.                                                              | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-caddy/edit`       |                                                
| `ENSURE_MANAGESIEVE_PORT_CONFIG` | Force managesieve port configuration.<br/>This port is used to manage filters.                                                            | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-managesieve/edit` |
| `ENSURE_STORAGE_CONFIG`          | Force storage configuration.                                                                                                              | `ON`    | `https://mail.$NC_DOMAIN/settings/store/aio-rocksdb/edit`        |
| `ENSURE_DIRECTORY_CONFIG`        | Force directory configuration.<br/>This is the systeme to manage users.                                                                   | `ON`    | `https://mail.$NC_DOMAIN/settings/directory/aio-rocksdb/edit`    |
| `ENSURE_FILE_LOGGING_CONFIG`     | Force file logging configuration.<br/>This provide access to logs form the web-admin.                                                     | `ON`    | `https://mail.$NC_DOMAIN/settings/tracing/aio-log/edit`          |
| `ENSURE_CONSOLE_LOGGING_CONFIG`  | Force console logging configuration.<br/>This provide access to logs form docker and mastercontainer interface.                           | `ON`    | `https://mail.$NC_DOMAIN/settings/tracing/aio-stdout/edit`       |
| `ENSURE_FALLBACK_ADMIN_CONFIG`   | Force fallback admin configuration.<br/>This is the admin account to access the web-admin.                                                | `ON`    | `https://mail.$NC_DOMAIN/settings/authentication/edit`           |
| `AUTO_CONFIG_TLS_CERT`           | Automatically configure TLS certificates from caddy community container.<br/>This is used to secure the connection for the mais protocol. | `ON`    | `https://mail.$NC_DOMAIN/settings/certificate/caddy-aio/edit`    |

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


### Upgrading from 0.8.x to 0.9.x

This migration does not require any action, but the organization of the database has changed.
Be vigilant about possible data loss.

The entrypoint script changes to. Be careful if you have made on settings managed by the entrypoint script.
See [Options](#options).

To unlock the server use the following command:
```bash
# verify the data version is in '0.8.0'
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.8.0 /opt/stalwart-mail/aio.lock

# Backup your configuration file
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.8.0 /opt/stalwart-mail/etc/config.toml > config.toml

# Set the new data version
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/sed stalwartlabs/mail-server:v0.9.0 -i 's/^0.8.0$/0.9/g' /opt/stalwart-mail/aio.lock
```

Then, go inside your AIO panel and restart and upgrade your container.

You can verify your config file with the following command after starting the container:
```bash
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.9.0 /opt/stalwart-mail/etc/config.toml
```


### Upgrading from 0.7.x to 0.8.x

To upgrade from 0.7.x to 0.8.x, you need to run the following command:

```bash
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Go inside container in 0.7.3
docker run --rm -it -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/bash stalwartlabs/mail-server:v0.7.3
```
    
Then, run the following command inside the container:

```bash
# Verify the dataversion is in '0.7.0'
cat /opt/stalwart-mail/aio.lock

# Export the data
stalwart-mail --config /opt/stalwart-mail/etc/config.toml --export /opt/stalwart-mail/export

# Exit the container
exit
```

Finally, run the following command to upgrade to 0.8.x:

```bash
# Go inside container in 0.8.0
docker run --rm -it -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/bash stalwartlabs/mail-server:v0.8.0
```

> [!NOTE]
> You can do a backup in the AIO panel before continuing.

Then, run the following command inside the container:

```bash
# Import the data
stalwart-mail --config /opt/stalwart-mail/etc/config.toml --import /opt/stalwart-mail/export

# Set the new dataversion
sed -i 's/^0.7.0$/0.8.0/g' /opt/stalwart-mail/aio.lock

# Exit the container
exit
```

Now go inside your AIO panel and restart and upgrade your container.
