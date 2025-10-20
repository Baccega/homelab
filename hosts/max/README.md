# Max Host Configuration

This directory contains the NixOS configuration for the `max` host, which serves as a media download server.

## Structure

```
max/
├── configuration.nix          # Main host configuration
├── disk-config.nix           # Disk partitioning setup
├── hardware-configuration.nix # Hardware-specific settings
├── home/
│   └── docker-compose.yml    # Docker services
└── modules/
    ├── qbittorrent.nix       # qBittorrent configuration with SOPS secrets
    └── sabnzbd.nix           # SABnzbd configuration with SOPS secrets
```

## Services

### Docker Services

All Docker services are managed via `docker-compose.yml`:

- **qBittorrent**: BitTorrent client with VPN proxy (port 8080)
- **SABnzbd**: Usenet download client (port 8081)
- **forward-proxy**: OpenVPN SOCKS5 proxy for download clients

## Service Execution Flow

1. **Boot**: `sops-nix.service` decrypts secrets
2. **Config Generation**:
   - `qbittorrent-config.service` generates qBittorrent config
   - `sabnzbd-config.service` generates SABnzbd config
3. **Home Manager**: Deploys `docker-compose.yml`
4. **Docker**: `docker-compose.service` starts containers

## Troubleshooting

### Check config generation

```bash
systemctl status qbittorrent-config.service
systemctl status sabnzbd-config.service
```

### Check Docker services

```bash
docker-compose -f /home/sandro/docker-compose.yml ps
docker-compose -f /home/sandro/docker-compose.yml logs qbittorrent
docker-compose -f /home/sandro/docker-compose.yml logs sabnzbd
```

### Manually regenerate configs

```bash
sudo systemctl restart qbittorrent-config.service
sudo systemctl restart sabnzbd-config.service
sudo systemctl restart docker-compose.service
```
