# Migrating an existing installation

Stop services that write to data being copied. Keep the old installation
available until reception, recording, playback and authenticated file sharing
have been verified on the new host.

## Mirakurun

Copy the persisted `/app-config` contents to
`/srv/my-kitchen/mirakurun/config/`, including channel files referenced by tuner
commands. `/app/config` in the container contains bundled defaults.

The container runs `pcscd`; the host playbook disables `pcscd.socket` to avoid
competition for the card reader.

## EPGStation and MariaDB

Use EPGStation's logical backup when moving between database versions. Do not
start a new MariaDB version against the old installation's data directory.

The backup script saves EPGStation metadata and a MariaDB SQL dump. Preserve
recordings and other service data separately. Stop EPGStation before restoring
metadata to avoid writes from the running application:

```sh
cd /srv/my-kitchen
docker compose stop epgstation
scripts/restore-epgstation.sh /path/to/backup.json
```

Ansible preserves existing application-directory ownership and permissions.
The generated MariaDB password is stored in `secrets/mariadb-password` and
supplied through a Docker Secret; preserve it with an existing database.

## Samba

Configuration alone does not migrate Samba accounts. With Samba stopped,
preserve `passdb.tdb` and `secrets.tdb` from `/var/lib/samba/private` to retain
passwords and server identity. Back up the destination databases first and
keep restored files owned by root with mode `0600`. Do not commit them to Git.

Verify client access using the existing account with SMB signing required.
The shares require authentication; guest access is disabled.

## Tailscale and Jellyfin

Preserve Tailscale's existing state to retain the device identity. Check
`tailscale status` and any routing or exit-node settings after migration.
Do not run the old and new hosts simultaneously with the same identity.

Jellyfin settings are provisioned by `ansible/applications.yml`, including on
an empty installation. Copying old configuration is not required for setup.
To retain viewing history and indexed metadata, migrate the persistent data
while Jellyfin is stopped, preserve library paths, and then apply Ansible with
the existing administrator credentials. Recordings are mounted at `/media`.

## Mackerel

Supply the existing API key as `mackerel_api_key` through Ansible Vault. To retain
the same monitored host, copy `/var/lib/mackerel-agent/id` before starting the
agent. Do not run two agents with the same identity. The role preserves this
file and manages agent configuration independently of the old installation.
