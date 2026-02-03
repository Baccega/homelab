# Useful Commands

## DHCP / Network

```bash
# List all DHCP leases (connected hosts)
sudo column -t -s, /var/lib/kea/dhcp4.leases

# View ARP table (recently active hosts)
ip neigh

# Scan subnet for all devices
nmap -sn 192.168.1.0/24
```

## Systemd

```bash
# Check status of systemd services
systemctl status <SERVICE_NAME>

# Restart a service
sudo systemctl restart <SERVICE_NAME>

# View last 50 lines of systemd logs
journalctl -u <SERVICE_NAME> -n 50

# Check Kea DHCP server status
systemctl status kea-dhcp4-server
```

## SOPS secrets

```bash
# Check if SOPS secrets are loaded
systemctl status sops-nix

# Verify secret files exist
ls -la /run/secrets/

# Re-run SOPS template generation
sudo systemctl restart sops-nix
```
