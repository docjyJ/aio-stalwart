> [!CAUTION]
> Do not use this feature as a main mail server without a redundancy system and proper knowledge.

> [!WARNING]
> Stalwart and Nextcloud community containers are solutions under development.
>
> The mail server is one of the most difficult services to deploy. 
> This solution is quite stable (used for my own cloud) but it is not enterprise quality.
>
> If you have any suggestions, questions, or want to report a bug, [open an issue](https://github.com/docjyj/aio-stalwart/issues)!

# Stalwart Community Container for Nextcloud All-In-One

This container is used in [Nextcloud All-In-One](https://github.com/nextcloud/all-in-one/tree/main/community-containers/stalwart) to provide a mail server. It works with the [Caddy community container](https://github.com/nextcloud/all-in-one/tree/main/community-containers/caddy) as a reverse proxy.

## Features

Compared to a default Stalwart container, this container allows:
- Automatic configuration of a mail server.
- Compatibility with Nextcloud All-In-One backups.
- *(Planned)* Synchronization of Nextcloud and Stalwart accounts.

## Getting Started

### Prerequisites

1. A server with a static IP address.
2. Ensure that ports `25`, `465`, `993`, `4190`, and `10003` are not used by another program. (Use `sudo netstat -tulpn` to list all used ports).
3. Deploy the [Caddy community container](https://github.com/nextcloud/all-in-one/tree/main/community-containers/caddy) as a reverse proxy. (Other solutions are possible, see: [Use Your Own Reverse Proxy](#use-your-own-reverse-proxy)).

### Installation

See [how to use community containers](https://github.com/nextcloud/all-in-one/tree/main/community-containers#how-to-use-this).

After installation on Nextcloud, go to `https://mail.$NC_DOMAIN/login` and log in with the following credentials:
- **Username**: `admin`
- **Password**: Get with the command `docker inspect nextcloud-aio-stalwart | grep STALWART_USER_PASS`

Once connected, add a domain, configure your DNS zone, and create your users.

Additionally, you might want to install and configure [Snappymail](https://apps.nextcloud.com/apps/snappymail) or [Mail](https://apps.nextcloud.com/apps/mail) inside Nextcloud to use your mail accounts for sending and retrieving emails.

### Export Data To Another Instance

If you want to change Stalwart server, you can export your data by following command:

```shell
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Export the data
docker run --rm -it -v nextcloud_aio_stalwart:/opt/stalwart-mail -v "$LOCATION:/export" --entrypoint /bin/stalwart-mail nextcloud_aio_stalwart --config /opt/stalwart-mail/etc/config.toml --export /export
```

Now your data is in the `$LOCATION` folder

### Import From Exported Data

To import your data to a new Stalwart server for the folder `$LOCATION`, use the following command with:

```shell
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Import the data
docker run --rm -it -v nextcloud_aio_stalwart:/opt/stalwart-mail -v "$LOCATION:/import" --entrypoint /bin/stalwart-mail nextcloud_aio_stalwart --config /opt/stalwart-mail/etc/config.toml --import /import
```

Now your data is imported, go inside your All-In-One panel and restart your container.

## Common Issues

### WebAdmin Show Errors

Try to update the container in the Nextcloud All-In-One panel.

If it doesn't resolve the issue, upgrade manually the WebAdmin with the following command:

```shell
docker exec -it nextcloud-aio-stalwart bash /webadmin.sh

# Or if you change the fallback admin password
docker exec -it nextcloud-aio-stalwart curl -k -u "$USER:$PASSWORD" http://127.0.0.1:10003/api/update/webadmin
```

## Advanced Configuration

> [!IMPORTANT]
> This image overrides the configuration of Stalwart on every start.
> You can find the list of all managed settings in the [Managed Settings](#managed-settings) section.
> The managed settings prevent breaking links with Nextcloud and the Caddy community container.

See the [Stalwart FAQ](https://stalw.art/docs/faq) for all possibilities.

For any questions, [open an issue](https://github.com/docjyj/aio-stalwart/issues)!

### Change the Admin Password

Before changing the password, disable the managed credential of fallback admin. See [Managed Settings](#managed-settings).

Then you can change the password in the WebAdmin.

### Use a Custom Domain

To configure a custom domain for the mail server, follow these steps:

1. Disable the managed configuration of certificates. See [Managed Settings](#managed-settings).
2. Configure your own reverse proxy. See [Use Your Own Reverse Proxy](#use-your-own-reverse-proxy).
3. Add your own certificate. See [Stalwart Certificate](https://stalw.art/docs/server/tls/certificates).

### Use Your Own Reverse Proxy

Redirect HTTP (or HTTPS) traffic from `mail.$NC_DOMAIN` to port `10003` of the `nextcloud-aio-stalwart` container in HTTP.

**Then add your own certificate.** See: [Use Your Own Certificate](#use-your-own-certificate)

Example with `Caddyfile` syntax:
```caddyfile
https://mail.{$NC_DOMAIN}:443 {
    reverse_proxy http://{$STALWART_HOSTNAME}:10003
}
```

### Use Your Own Certificate

Add a certificate in volume `nextcloud_aio_caddy` in this path:
- `$VOLUME_ROOT/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.key`
- `$VOLUME_ROOT/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.$NC_DOMAIN/mail.$NC_DOMAIN.crt`

If you're using Caddy, mount the volume `nextcloud_aio_caddy` to your Caddy container and add this [storage global directive](https://caddyserver.com/docs/caddyfile/options#storage):
```caddyfile
{
    storage file_system {$VOLUME_ROOT}/caddy
}
```

**If you're using another domain**, disable the managed configuration of certificates. See [Managed Settings](#managed-settings) and [Stalwart Certificate](https://stalw.art/docs/server/tls/certificates).

## Managed Settings

Disable some automatic override configurations with environment variables in the file `/opt/stalwart-mail/etc/aio-config.env`.

| Variable                         | Description                                                                                                                                   | Default | WebAdmin URL                                                     |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|---------|------------------------------------------------------------------|
| `SECURE_DATA_AFTER_UPGRADE`      | Prevent the server from starting if the data is in an old format.                                                                             | `ON`    |                                                                  |
| `ENSURE_MAIL_PORT_CONFIG`        | Manage mail exchange port configuration.<br/>This port is used to receive emails.                                                             | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-mail/edit`        |
| `ENSURE_SUBMISSION_PORT_CONFIG`  | Manage mail submission port configuration.<br/>This port is used to send emails.                                                              | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-submission/edit`  |
| `ENSURE_IMAP_PORT_CONFIG`        | Manage IMAP port configuration.<br/>This port is used to read emails.                                                                         | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-imap/edit`        |
| `ENSURE_WEB_PORT_CONFIG`         | Manage web port configuration.<br/>This port is used to access the WebAdmin.                                                                  | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-caddy/edit`       |
| `ENSURE_MANAGESIEVE_PORT_CONFIG` | Manage managesieve port configuration.<br/>This port is used to manage filters.                                                               | `ON`    | `https://mail.$NC_DOMAIN/settings/listener/aio-managesieve/edit` |
| `ENSURE_STORAGE_CONFIG`          | Manage storage configuration.                                                                                                                 | `ON`    | `https://mail.$NC_DOMAIN/settings/store/aio-rocksdb/edit`        |
| `ENSURE_DIRECTORY_CONFIG`        | Manage directory configuration.<br/>This is the system to manage users.                                                                       | `ON`    | `https://mail.$NC_DOMAIN/settings/directory/aio-rocksdb/edit`    |
| `ENSURE_FILE_LOGGING_CONFIG`     | Manage file logging configuration.<br/>This provides access to logs from the WebAdmin.                                                        | `ON`    | `https://mail.$NC_DOMAIN/settings/tracing/aio-log/edit`          |
| `ENSURE_CONSOLE_LOGGING_CONFIG`  | Manage console logging configuration.<br/>This provides access to logs from Docker and the master container interface.                        | `ON`    | `https://mail.$NC_DOMAIN/settings/tracing/aio-stdout/edit`       |
| `ENSURE_FALLBACK_ADMIN_CONFIG`   | Manage fallback admin configuration.<br/>This is the admin account to access the WebAdmin.                                                    | `ON`    | `https://mail.$NC_DOMAIN/settings/authentication/edit`           |
| `AUTO_CONFIG_TLS_CERT`           | Manage configuration of TLS certificates from the Caddy community container.<br/>This is used to secure the connection for the mail protocol. | `ON`    | `https://mail.$NC_DOMAIN/settings/certificate/caddy-aio/edit`    |

## Upgrading

> [!NOTE]
> Unless the starting script tells you, you have no action to do to update.

See [Stalwart Upgrading Guide](https://github.com/stalwartlabs/mail-server/blob/main/UPGRADING.md).

During a major server update, this message will be displayed:

```
Your data is in an old format.
Make a backup and see https://github.com/docjyJ/aio-stalwart#Upgrading
To avoid any loss of data, Stalwart will not launch.
```

> [!CAUTION]
> Before each update, don't forget to make a backup.

### Upgrading from 0.9.x to 0.10.x

To upgrade from 0.9.x to 0.10.x, run the following command:

```shell
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Check the data version is in 0.9 (output should be '0.9')
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.9.4 /opt/stalwart-mail/aio.lock

# Enable the new data version
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/sed stalwartlabs/mail-server:v0.10.0 -i 's/^0.9$/0.10/g' /opt/stalwart-mail/aio.lock
```

Then, go inside your All-In-One panel and restart your container.

### Upgrading from 0.8.x to 0.9.x

This migration does not require any action, but the organization of the database and autoconfiguration script has changed.

1. Be vigilant about possible the data loss, see [Stalwart 0.9.0](https://github.com/stalwartlabs/mail-server/releases/tag/v0.9.0)
2. Be careful if you have made any settings, the autoconfiguration script might overwrite them, see [Managed Settings](#managed-settings).

To upgrade from 0.8.x to 0.9.x, run the following steps:

```shell
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Check the data version is in 0.8.0 (output should be '0.8.0')
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.8.0 /opt/stalwart-mail/aio.lock

# BACKUP YOUR CONFIGURATION FILE
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.9.0 /opt/stalwart-mail/etc/config.toml

# Enable the new data version
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/sed stalwartlabs/mail-server:v0.9.0 -i 's/^0.8.0$/0.9/g' /opt/stalwart-mail/aio.lock
```

Then, go inside your All-In-One panel and restart your container.

You can verify your config file with the following command after starting the container:
```shell
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.9.0 /opt/stalwart-mail/etc/config.toml
```

### Upgrading from 0.7.x to 0.8.x

To upgrade from 0.7.x to 0.8.x, run the following steps:

```shell
# Stop stalwart-mail container
docker stop nextcloud-aio-stalwart

# Check the data version is in 0.7.0 (output should be '0.7.0')
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/cat stalwartlabs/mail-server:v0.7.3 /opt/stalwart-mail/aio.lock

# Export your data
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/stalwart-mail stalwartlabs/mail-server:v0.7.3 --config /opt/stalwart-mail/etc/config.toml --export /opt/stalwart-mail/export_7_to_8

# Import your data
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/stalwart-mail stalwartlabs/mail-server:v0.8.0 --config /opt/stalwart-mail/etc/config.toml --import /opt/stalwart-mail/export_7_to_8

# Enable the new data version
docker run --rm -v nextcloud_aio_stalwart:/opt/stalwart-mail --entrypoint /bin/sed stalwartlabs/mail-server:v0.8.0 -i 's/^0.7.0$/0.8.0/g' /opt/stalwart-mail/aio.lock
```

Now go inside your All-In-One panel and restart and upgrade yours containers.
