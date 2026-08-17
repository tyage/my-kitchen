# Recording-host migration

The old and new stacks should not access the tuner or the EPGStation database
at the same time. Keep the old SSD unchanged until final verification is
complete; it is the fastest rollback path.

## Before replacing the SSD

1. Record the current tuner device names and copy the effective Mirakurun
   `channels.yml` and `tuners.yml`.
2. Export the EPGStation database from the running EPGStation container:

   ```sh
   docker compose exec epgstation npm run backup config/backup.json
   ```

3. Copy `backup.json`, the entire EPGStation configuration directory, and any
   data that is not reproducible. Recording files are not included in the
   EPGStation backup.
4. Record ownership and group IDs for `/dev/dri`, `/dev/dvb`, the recording
   directory and the Samba share.

## Build the new host

1. Install Ubuntu 26.04 and the tuner driver.
2. Run the Ansible playbook from the README.
3. Configure `compose/mirakc/config.yml` and start only mirakc.
4. Confirm `/api/version`, `/api/services` and a raw stream from every tuner.
5. Confirm `vainfo` on the host and `/dev/dri` inside the EPGStation container.
6. Start MariaDB and EPGStation, then restore the logical backup:

   ```sh
   cd /srv/my-kitchen
   cp /path/to/backup.json epgstation/config/backup.json
   docker compose run --rm epgstation npm run restore config/backup.json
   docker compose up -d epgstation
   ```

7. Make a short test recording and run the `H.265 (QSVEnc)` encode preset.
   Check video, main/sub audio, subtitles and A/V sync before enabling rules.
8. Enable Jellyfin and Samba only after the recording path is stable.

## Rollback

Stop the new stack and reinstall the old SSD. Do not point the old EPGStation
at the MariaDB data directory created by the new image. Restore through an
EPGStation logical backup when moving data between versions.
