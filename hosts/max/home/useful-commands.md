# Useful Commands

## Container Management

```bash
# List running containers
sudo podman ps

# View logs for a service
sudo podman logs <SERVICE_NAME>

# Open shell in a service container
sudo podman exec -it <SERVICE_NAME> /bin/bash

# Check status of podman services
systemctl status podman-<SERVICE_NAME>

# Restart via systemd (NixOS way)
sudo systemctl restart podman-<SERVICE_NAME>
```

## Systemd

```bash
# Check status of systemd services
systemctl status <SERVICE_NAME>

# Restart via systemd (NixOS way)
sudo systemctl restart <SERVICE_NAME>

# View last 50 lines of systemd logs
journalctl -u <SERVICE_NAME> -n 50
```

## SOPS secrets

```bash
# Check if SOPS secrets are loaded
systemctl status sops-nix

# Verify secret files exist
ls -la /run/secrets/<SECRET_NAME>

# Re-run config generation (loads new secrets)
sudo systemctl restart <SERVICE_NAME>-config
```
