{ advertiseRoutes ? [] }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  advertiseRoutesFlag = builtins.concatStringsSep "," advertiseRoutes;
in
{
  # Enable Tailscale
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraUpFlags = lib.optionals (advertiseRoutes != []) [
      "--advertise-routes=${advertiseRoutesFlag}"
    ];
  };

  # Add tailscale to system packages for easy CLI access
  environment.systemPackages = [ pkgs.tailscale ];
}
