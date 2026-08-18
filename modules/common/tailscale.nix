{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable Tailscale
  # MagicDNS would overwrite /etc/resolv.conf with 100.100.100.100 and send
  # *.baccegasandro.dev to Cloudflare. LAN split-view DNS on Nemo must win.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--accept-dns=false" ];
    extraUpFlags = [ "--accept-dns=false" ];
  };

  # Add tailscale to system packages for easy CLI access
  environment.systemPackages = [ pkgs.tailscale ];
}
