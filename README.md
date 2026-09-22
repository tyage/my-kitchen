# my-kitchen

Ansible and Docker Compose configuration for an Ubuntu recording server.

- **Recording:** Mirakurun, EPGStation and MariaDB, with Intel QSV encoding
- **Playback:** Jellyfin
- **Host services:** Samba, Tailscale and Mackerel

## Getting started

See [deployment and operations](docs/deployment.md) for setup, credentials,
service startup and maintenance, or [migration](docs/migration.md) to move an
existing installation.

Host settings and image versions are defined in
[`ansible/group_vars/all/main.yml`](ansible/group_vars/all/main.yml).
