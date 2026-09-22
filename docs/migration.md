# Migration

Stop services before copying their data. Keep the old installation until
recording, playback and authenticated file sharing work on the new host.
Do not run old and new hosts simultaneously with the same service identities.

## Recordings and database

Copy Mirakurun's persisted `/app-config` contents, including referenced channel
files, to `/srv/my-kitchen/mirakurun/config/`.

Use EPGStation's logical backup across database versions; do not open an old
MariaDB data directory with a new version. Restore with:

```sh
cd /srv/my-kitchen
docker compose stop epgstation
scripts/restore-epgstation.sh /path/to/backup.json
```

Copy recordings separately. When retaining an existing database, preserve its
`secrets/mariadb-password` too.

## Accounts and service data

- **Samba:** with Samba stopped, back up the destination databases and copy
  `passdb.tdb` and `secrets.tdb` from `/var/lib/samba/private`. Keep them root-owned,
  mode `0600`. Verify access with the existing account and SMB signing enabled.
- **Tailscale:** preserve its state to retain device identity; verify
  `tailscale status` and routing settings after migration.
- **Jellyfin:** to retain viewing history and metadata, copy its persistent data
  while stopped. Apply `ansible/applications.yml` using existing administrator
  credentials and matching library names and paths (`/media` inside the container).
- **Mackerel:** set `mackerel_api_key` in the local `ansible/vault.yml` and copy
  `/var/lib/mackerel-agent/id` before starting the agent to retain host identity.
