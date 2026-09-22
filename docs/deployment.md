# Deployment and operations

Requires Ubuntu 26.04+ (amd64), an Intel GPU, a supported tuner, a recording
disk mounted at `/videos/recorded`, and a host user with sudo access.
Run Ansible commands from the repository root on your management machine.

## Deploy

Copy and edit the inventory, review [host settings](../ansible/group_vars/all/main.yml),
and store `mackerel_api_key` and `jellyfin_admin_password` in Vault.

```sh
cp ansible/inventory.example.yml ansible/inventory.yml
ansible-vault create ansible/vault.yml
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.yml ansible/site.yml -e @ansible/vault.yml --ask-vault-pass
```

Add `--ask-become-pass` if sudo requires a password.

On the server, place Mirakurun's `server.yml`, `tuners.yml`, `channels.yml` and
referenced channel files in `/srv/my-kitchen/mirakurun/config/`, then run:

```sh
cd /srv/my-kitchen
docker compose build epgstation
docker compose up -d
scripts/check.sh
```

Apply application settings from the management machine:

```sh
ansible-playbook -i ansible/inventory.yml ansible/applications.yml \
  -e @ansible/vault.yml --ask-vault-pass
```

For existing Jellyfin installations, use the current administrator credentials
and match `jellyfin_libraries` to the existing library names and paths.

On a new server, register Samba credentials with `sudo smbpasswd -a tyage`
and authenticate Tailscale with `sudo tailscale up`. Configure and approve
exit-node routing separately if needed.

## Access and maintenance

- Mirakurun: port `40772`; EPGStation: `8888`; Jellyfin: `8096`.
- Samba: `share/recorded` or `recorded`, using the configured host user's credentials.
- Verify reception, a test recording and playback after deployment.

Run from `/srv/my-kitchen`:

```sh
docker compose ps
docker compose logs --tail 100 epgstation
scripts/check.sh
scripts/backup.sh
```

Backups include EPGStation metadata and a MariaDB dump; save recording files
separately. See [migration](migration.md) for restoration.
When upgrading Mackerel, update both its package URL and SHA-256 checksum.
