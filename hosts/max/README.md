# Max Host Configuration

This directory contains the NixOS configuration for the `max` host.

## Structure

```
max/
├── configuration.nix          # Main host configuration
├── disk-config.nix           # Disk partitioning setup
├── hardware-configuration.nix # Hardware-specific settings
├── hardware/
│   ├── nvidia-gtx-1050ti.nix # GTX 1050 Ti
│   └── nvidia-tesla-p4.nix   # Tesla P4
├── home/
│   ├── docker-compose.yml    # Reference Docker services (migrating to Podman)
│   └── useful-commands.md    # Podman and systemd management commands
└── modules/
    ├── qbittorrent.nix       # qBittorrent configuration with SOPS secrets
    ├── sabnzbd.nix           # SABnzbd configuration with SOPS secrets
    └── forward-proxy.nix     # OpenVPN SOCKS5 proxy configuration
```

## Services

### Container Services (Podman)

- **qBittorrent**: BitTorrent client with VPN proxy (port 8080, podman-qbittorrent.service)
- **SABnzbd**: Usenet download client (port 8081, podman-sabnzbd.service)
  - sabnzbd-config.service
- **forward-proxy**: OpenVPN SOCKS5 proxy for download clients (port 1080, podman-forward-proxy.service)

### Systemd Services

- **backup-<SERVICE_NAME>-configs**: Automated backup service using rsync to NFS-mounted NAS
- **nas-fetch-<SERVICE_NAME>-configs**: One-way fetch service from NAS to local filesystem (If there are no local configuration files in the host)
- **<MOUNT_POINT_NAME>.mount**: Automated mounting of NAS shares for media and configurations (e.g., downloads.mount, movies.mount, tv_shows.mount, configurations.mount)

## Service Execution Flow

1. **Boot**:
   - NFS automounts establish connections to NAS
2. **NAS Fetch**: Fetch service to pull configuration data from NAS
3. **Config Generation**:
   - `sabnzbd-config.service` generates SABnzbd config
4. **Container Services**: Podman systemd services start containers
5. **Backup Services**: Automated backup jobs sync local data to NAS

## Immich on Max

Immich runs at `https://immich.baccegasandro.dev`. Nemo serves it through Caddy
and split DNS. Use the LAN for normal browser sign-in. Remote clients must send
the two Cloudflare Access service-token headers before Immich sign-in.

### Before deployment

1. Confirm that `192.168.20.233` is available and that Max has enough free space
   under `/var/lib/immich` for originals, previews, videos, and PostgreSQL. Size
   the configurations NAS share for the media and retained restic snapshots.
2. In Cloudflare Zero Trust → Access controls → Service credentials → Service
   Tokens, create an Immich token with an expiration date. Save the Client ID
   and Client Secret in your password manager. In Access controls → Applications,
   create a Self-hosted application for all paths on
   `immich.baccegasandro.dev`. Add a **Service Auth** policy with **Include →
   Service Token** and select that token. Save the policy before you publish the
   route. [Cloudflare service tokens](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/)

### After deployment

1. On the LAN, open `https://immich.baccegasandro.dev` and create the first
   Immich administrator account before you publish the Tunnel route. In
   Administration → Settings → Machine Learning, confirm the URL is
   `http://immich-machine-learning:3003`.
2. In Cloudflare Networking → Tunnels, select Nemo's existing tunnel. Under
   Routes add a Published application for `immich.baccegasandro.dev` with
   service URL `http://127.0.0.1:80` and HTTP Host Header
   `immich.baccegasandro.dev`. Enable **Protect with Access** using the team
   name and this application's AUD tag. Keep the route on the tunnel and
   leave the origin ports private.
   [Cloudflare origin settings](https://developers.cloudflare.com/tunnel/reference/origin-parameters/)
3. From outside the LAN, check that a request to `/api/server/ping` without
   headers is blocked by Access, and that the same request with
   `CF-Access-Client-Id` and `CF-Access-Client-Secret` returns Immich's
   `{"res":"pong"}`. Add both headers in the mobile app's custom headers
   settings and sign in with your Immich account. Keep these credentials out
   of Git, Nix and shared logs. Renew or replace the token before it expires.
4. Verify photo upload, asset download and video playback over cellular.
   Mobile custom headers are experimental and can affect each of these
   operations. Cloudflare also caps request bodies at 100 MB on Free and Pro,
   200 MB on Business, and up to 5 GB on Enterprise. The zone can set a lower
   limit. Oversized requests receive HTTP 413. Use the LAN path for large
   uploads or if mobile headers interfere with asset transfer.
   [Immich FAQ](https://docs.immich.app/FAQ/) ·
   [Cloudflare upload limits](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/4xx-client-error/error-413/)

### Data and recovery

The service generates its PostgreSQL password on Max under
`/var/lib/immich/credentials`. Keep that directory private. PostgreSQL uses
local disk under `/var/lib/immich/postgres`. The model cache is replaceable.

The daily `backup-immich.service` dumps PostgreSQL before backing up
`/var/lib/immich/backup` to the restic repository at
`/mnt/configurations/immich`. The snapshot covers `immich.dump` and the entire
`media/` tree. The NAS must be mounted and the dump must succeed before restic
can take a snapshot. Retain access to `/mnt/configurations/.restic-password`
for recovery. The running service can change media during a backup. For a
matched recovery point, stop `podman-immich-server` for the whole backup.

Run `sudo systemctl start backup-immich.service` after the first test upload.
Check the unit log and restore its snapshot to a scratch location. On an
isolated recovery host, restore `media/` to `/var/lib/immich/backup/media`.
Start only the matching PostgreSQL container with an empty database and a
fresh runtime password. With the server stopped, copy and restore the archive.

```sh
sudo podman cp immich.dump immich-postgres:/tmp/immich.dump
sudo podman exec immich-postgres pg_restore --exit-on-error -U immich -d immich /tmp/immich.dump
sudo podman exec immich-postgres rm /tmp/immich.dump
```

Then start Immich at the backed-up version and check that the test asset opens.
Complete this check before relying on Immich as a photo backup.
[Immich backup ordering](https://docs.immich.app/administration/backup-and-restore/#backup-ordering)

For rollback, remove the Tunnel route and revert the Max and Nemo
configuration. Keep the local data and restic snapshots for recovery.
