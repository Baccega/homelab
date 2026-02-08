{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable Tailscale
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Add tailscale to system packages for easy CLI access
  environment.systemPackages = [ pkgs.tailscale ];
}
