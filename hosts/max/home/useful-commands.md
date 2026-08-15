# Useful Commands

## NixOS

# Rebuild and switch (no reboot)
```bash
sudo nixos-rebuild switch --flake github:Baccega/homelab#max
```

# Rebuild and reboot
```bash
sudo nixos-rebuild boot --flake github:Baccega/homelab#max
```

## Gaming VM (bolt)

```bash
# Requires Intel VT-d enabled in BIOS (IOMMU groups > 0).
# Check passthrough binding after reboot:
lspci -nnk -d 10de:1c82
find /sys/kernel/iommu_groups -type l | wc -l

# Libvirt
sudo virsh list --all
sudo virsh start bolt
sudo virsh console bolt
sudo virsh shutdown bolt
```

## Bolt guest – save emulator configs to Hachiko

Daily backups already run; to push immediately after tweaking PCSX2/RetroArch/Sunshine:

```bash
sudo systemctl start backup-pcsx2-configs
sudo systemctl start backup-retroarch-configs
sudo systemctl start backup-sunshine-configs
```


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
# sudo systemctl restart "podman-*"
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

## Ollama

```bash
# List available models
sudo podman exec -it <CONTAINER_ID> ollama pull <MODEL_NAME>
```