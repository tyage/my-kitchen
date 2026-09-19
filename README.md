# my-kitchen

Home-server configuration, rebuilt for the Ubuntu 26.04 recording host.

- `ansible/`: host setup (Docker, Intel GPU, Tailscale, Samba and directories)
- `compose/`: Mirakurun, EPGStation, MariaDB and optional Jellyfin

## 1. Provision the host

Install Ansible on the machine used to manage the server, then:

```sh
ansible-galaxy collection install -r ansible/requirements.yml
cp ansible/inventory.example.yml ansible/inventory.yml
ansible-playbook -i ansible/inventory.yml ansible/site.yml --check --diff
ansible-playbook -i ansible/inventory.yml ansible/site.yml
```

The playbook copies the Compose project to `/srv/my-kitchen` but does not start
it. Tailscale authentication remains an explicit manual step. Samba preserves the
previous writable `\\server\share\recorded` path by exposing
`/videos` as `share`. It also exposes `/videos/recorded` directly as `recorded`;
shares require authentication as the recording user (`tyage` by default), and
files are created as that user. Guest access is disabled so clients can require
SMB signing. For migration, preserve the old Samba `passdb.tdb` and `secrets.tdb`
from `/var/lib/samba/private` with Samba stopped, root ownership and mode 0600;
keep a protected backup of the destination databases first. These files contain
credentials and must not be committed to Git. On a fresh host, provision the
Samba password interactively with `sudo smbpasswd -a tyage` before connecting.
The MariaDB
application password is generated once in
`/srv/my-kitchen/secrets/mariadb-password`; it is not stored in Git or exposed
through the Compose environment.

Existing application directories retain their ownership and permissions during
provisioning, including the container-owned MariaDB data directory. Tailscale
keeps its existing authentication state; `tailscale_ip_forwarding` enables
persistent IPv4/IPv6 forwarding for this host's existing exit-node setup.
New Tailscale devices still require explicit login and exit-node approval.

## 2. Configure the tuner

Copy the current Mirakurun `server.yml`, `tuners.yml` and `channels.yml` into
`/srv/my-kitchen/mirakurun/config/` before starting the new host. If the
directory is empty, Mirakurun creates default files on first startup; configure
or scan the channels from its Web UI before moving any EPGStation data.

For an existing Docker deployment, use its persisted `/app-config` directory
as the source. `/app/config` contains bundled defaults. Also preserve any
channel files referenced by the tuner commands.

The official image runs `pcscd` and installs the B25 test decoder inside the
container. Keep the host `pcscd.socket` disabled to avoid competing for the
card reader.

```sh
cd /srv/my-kitchen
docker compose up -d mirakurun
curl -fsS http://localhost:40772/api/version
```

## 3. Start the recording stack

```sh
cd /srv/my-kitchen
docker compose build epgstation
docker compose up -d mariadb mirakurun epgstation
docker compose ps
```

EPGStation is available on port `8888`. Jellyfin is optional:

```sh
docker compose --profile media up -d jellyfin
```

Operational checks and backups are explicit scripts:

```sh
scripts/check.sh
scripts/backup.sh
scripts/restore-epgstation.sh /path/to/backup.json
```

Versions checked on 2026-09-19: Mirakurun 4.1.3, EPGStation 2.10.0,
MariaDB 11.4.13 (maintained LTS), QSVEnc 8.30, FFmpeg 8.1.2 and
Jellyfin 12.1. Jellyfin remains optional; enable the `media` profile only
after recording is stable. The encoder container stays on Ubuntu 24.04
for compatibility with the upstream QSVEnc package and Intel repository.
