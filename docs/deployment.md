# Deployment and operations

Requires Ubuntu 26.04+ (amd64), an Intel GPU, a supported tuner, a recording
disk mounted at `/videos/recorded`, and a host user with sudo access.
Bundled tuner/channel settings target PT3 and the current Kansai reception setup;
edit `ansible/roles/recording_host/files/mirakurun/` for other hardware or regions.

## Deploy

Run from the repository root on your management machine:

```sh
cp ansible/vault.example.yml ansible/vault.yml
chmod 600 ansible/vault.yml
# Review inventory.yml and fill in vault.yml.
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.yml ansible/deploy.yml -e @ansible/vault.yml
```

Review [host settings](../ansible/group_vars/all/main.yml). Add `--ask-become-pass`
if sudo requires a password.
A new Samba account needs `samba_password`; a new Tailscale device needs
`tailscale_auth_key`. When first using the device as an exit node, approve it
in Tailscale's admin console unless your tailnet automatically approves it.
For existing Jellyfin installations, use the current administrator credentials
and match `jellyfin_libraries` to the existing library names and paths.

The playbook checks the disk mount, configures the host, installs dotfiles,
builds missing images and starts the services. It refuses changes while the
recorder reports an active recording or a running recorder cannot be queried.

## Access and maintenance

- Mirakurun: port `40772`; EPGStation: `8888`; Jellyfin: `8096`.
- Samba: `share/recorded` or `recorded`, with the configured user's credentials.
- Verify reception, a test recording and playback after deployment.

Run from `/srv/my-kitchen` on the server:

```sh
docker compose ps
docker compose logs --tail 100 epgstation
scripts/check.sh
scripts/backup.sh
```

Backups include EPGStation metadata and a MariaDB dump; save recordings
separately. See [migration](migration.md) for restoration.
Update both Mackerel's package URL and SHA-256 checksum when upgrading it.
