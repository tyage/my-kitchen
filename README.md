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
it. Tailscale authentication and Samba password setup remain explicit manual
steps. The MariaDB application password is generated once in
`/srv/my-kitchen/secrets/mariadb-password`; it is not stored in Git or exposed
through the Compose environment.

## 2. Configure the tuner

Copy the current Mirakurun `server.yml`, `tuners.yml` and `channels.yml` into
`/srv/my-kitchen/mirakurun/config/` before starting the new host. If the
directory is empty, Mirakurun creates default files on first startup; configure
or scan the channels from its Web UI before moving any EPGStation data.

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

`JELLYFIN_IMAGE` defaults to `latest` because Jellyfin is optional. Pin it in
`ansible/group_vars/all/main.yml` before enabling the `media` profile.
