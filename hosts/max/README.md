# Max Host Configuration

This directory contains the NixOS configuration for the `max` host.

## Structure

```
max/
├── configuration.nix          # Main host configuration
├── disk-config.nix           # Disk partitioning setup
├── hardware-configuration.nix # Hardware-specific settings
├── hardware/
│   └── nvidia-1050ti.nix     # NVIDIA GPU configuration
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
- **mnt-<MOUNT_POINT_FOLDER>.mount**: Automated mounting of NAS shares for media and configurations

## Service Execution Flow

1. **Boot**:
   - NFS automounts establish connections to NAS
2. **NAS Fetch**: Fetch service to pull configuration data from NAS
3. **Config Generation**:
   - `sabnzbd-config.service` generates SABnzbd config
4. **Container Services**: Podman systemd services start containers
5. **Backup Services**: Automated backup jobs sync local data to NAS
