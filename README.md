# my-kitchen

Home-server configuration, rebuilt for the Ubuntu 26.04 recording host.

- `ansible/`: host setup (Docker, Intel GPU, Tailscale, Samba and directories)
- `compose/`: mirakc, EPGStation, MariaDB and optional Jellyfin

See [MIGRATION.md](MIGRATION.md) for the migration order and rollback points.

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
steps.

## 2. Configure the tuner

`compose/mirakc/config.yml` intentionally contains no tuner or channel entries.
Copy the corresponding values from the current Mirakurun configuration and use
commands supported by the new tuner driver. Test mirakc before moving any
EPGStation data:

The official mirakc image contains `recpt1` and `recdvb` without B25 support.
If the tuner does not output decoded TS, configure a compatible decode filter
instead of copying the old Mirakurun command blindly.

```sh
cd /srv/my-kitchen
docker compose up -d mirakc
curl -fsS http://localhost:40772/api/version
```

## 3. Start the recording stack

```sh
cd /srv/my-kitchen
docker compose build epgstation
docker compose up -d mariadb mirakc epgstation
docker compose ps
```

EPGStation is available on port `8888`. Jellyfin is optional:

```sh
docker compose --profile media up -d jellyfin
```

Operational checks and backups are explicit scripts:

```sh
compose/scripts/check.sh
compose/scripts/backup.sh
compose/scripts/restore-epgstation.sh /path/to/backup.json
```

`JELLYFIN_IMAGE` defaults to `latest` because Jellyfin is optional. Pin it in
`ansible/group_vars/all/main.yml` before enabling the `media` profile.
