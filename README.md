# my-kitchen

Ansible and Docker Compose configuration for an Ubuntu recording server.

- **Recording:** Mirakurun, EPGStation and MariaDB, with Intel QSV encoding
- **Playback:** Jellyfin
- **Host services:** Samba, Tailscale and Mackerel

## Requirements

- Ubuntu 26.04 or newer, a supported tuner and an Intel GPU
- A recording directory mounted at `/videos/recorded` by default
- An existing host user with sudo access
- Ansible on the machine used to manage the server

## Configure and deploy

Copy the inventory example and edit the host connection settings. Review
[`ansible/group_vars/all/main.yml`](ansible/group_vars/all/main.yml) for the
host user, directories, host services and container images.

```sh
cp ansible/inventory.example.yml ansible/inventory.yml
ansible-vault create ansible/vault.yml
# Set mackerel_api_key and jellyfin_admin_password in this encrypted file.
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.yml ansible/site.yml -e @ansible/vault.yml --ask-vault-pass --check
ansible-playbook -i ansible/inventory.yml ansible/site.yml -e @ansible/vault.yml --ask-vault-pass
```

Add `--ask-become-pass` if sudo requires a password. Ansible installs host
dependencies and writes the Compose project to `/srv/my-kitchen`; starting
or rebuilding application containers is a separate step.

## Start recording services

Place Mirakurun's `server.yml`, `tuners.yml`, `channels.yml` and any referenced
channel files in `/srv/my-kitchen/mirakurun/config/`. See the
[migration guide](docs/migration.md) when moving an existing installation.

Run on the server:

```sh
cd /srv/my-kitchen
docker compose build epgstation
docker compose up -d
scripts/check.sh
```

Open Mirakurun on port `40772`, EPGStation on port `8888` and Jellyfin on port
`8096`. Verify reception
and a test recording before relying on scheduled recordings.

Apply application settings through Ansible:

```sh
ansible-playbook -i ansible/inventory.yml ansible/applications.yml \
  -e @ansible/vault.yml --ask-vault-pass
```

Application settings live in `ansible/group_vars/all/main.yml`. Jellyfin runs
under Compose; Ansible creates its initial administrator, configures the
`/media` movie library and folder view, and installs the pinned DLNA plugin.
No previous configuration backup or dashboard setup is required. On an existing
server, supply its administrator credentials and set `jellyfin_libraries` to the
existing library names before applying. Paths of named libraries are reconciled;
unlisted libraries and unrelated settings are preserved. Changing a library's
type fails rather than deleting its metadata. Credentials are inputs, while
viewing history and indexed media remain runtime data.

The CI integration test provisions empty Jellyfin volumes and checks that a
second reconciliation makes no changes. LAN discovery and playback on physical
DLNA clients require a separate hardware test.

## File sharing and remote access

Samba requires the configured host user's credentials (`tyage` by default).
On a new installation, register its Samba password with `sudo smbpasswd -a tyage`.
Recordings are available through the `share` share's `recorded` directory,
or directly through the `recorded` share.

For a new Tailscale device, run `sudo tailscale up` and complete authentication.
`tailscale_ip_forwarding` controls host IPv4/IPv6 forwarding; advertising and
approving an exit node are separate Tailscale configuration steps.

## Operations

Mackerel's agent, configuration and systemd service are managed by Ansible.
The amd64 deb release is pinned by HTTPS URL and SHA-256 checksum; update both
package variables when upgrading. Set `mackerel_roles` to service/role pairs such as `recording:server`
and optionally set `mackerel_display_name`. The API key is required when
`mackerel_enabled` is true; a missing key fails before provisioning. Configuration
is validated before replacement and restarts the agent only when it changes.
Existing `/var/lib/mackerel-agent/id` is preserved; a new installation registers
a new host. Dashboard alert policies are not managed by this role.

Run from `/srv/my-kitchen`:

```sh
docker compose ps
docker compose logs --tail 100 epgstation
scripts/check.sh
scripts/backup.sh
```

The backup script saves EPGStation metadata and a MariaDB SQL dump, not recording
files or all service data. Restore instructions are in the [migration guide](docs/migration.md).
Image versions are defined in `ansible/group_vars/all/main.yml`; encoder build
versions are in [`compose/epgstation/Dockerfile`](compose/epgstation/Dockerfile).
