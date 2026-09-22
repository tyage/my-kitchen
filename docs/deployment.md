# Deployment and operations

Target: Ubuntu 26.04+ (amd64), Intel GPU, PT3, and a recording disk mounted
at `/videos/recorded`. Channel settings are for Kansai.

## Setup

Run once from the repository root:

```sh
cp ansible/vault.example.yml ansible/vault.yml
chmod 600 ansible/vault.yml
ansible-galaxy collection install -r ansible/requirements.yml
```

Set `mackerel_api_key` and `jellyfin_admin_password` in `ansible/vault.yml`.
For a new Samba account or Tailscale device, also set `samba_password` or
`tailscale_auth_key`, respectively.

## Deploy

```sh
ansible-playbook -i ansible/inventory.yml ansible/deploy.yml -e @ansible/vault.yml
```

Add `--ask-become-pass` if sudo requires a password. Run when no recording is active.

## Operations

Mirakurun listens on port `40772`, EPGStation on `8888`, and Jellyfin on `8096`.
Samba shares are `share/recorded` and `recorded`.

Run from `/srv/my-kitchen` on the server:

```sh
docker compose ps
docker compose logs --tail 100 epgstation
scripts/check.sh
scripts/backup.sh
```

The backup script saves EPGStation metadata and a MariaDB dump, not recording
files. See [migration](migration.md) for restoration.
