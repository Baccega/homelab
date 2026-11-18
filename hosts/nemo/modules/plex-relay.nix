{ config, lib, pkgs, ... }:
let
  plex = (import ../../../constants.nix).services.plex;
in
{
  options.homelab.fido = lib.mkOption {
    default = null;
    description = "Fido's Tailscale addresses. Set both to enable the Plex relay.";
    type = lib.types.nullOr (lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.strMatching "100[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}";
          description = "Fido's Tailscale IPv4 address.";
        };
        ipv6 = lib.mkOption {
          type = lib.types.strMatching "fd7a:115c:a1e0:[0-9a-f:]+";
          description = "Fido's Tailscale IPv6 address.";
        };
      };
    });
  };

  config = lib.mkIf (config.homelab.fido != null) {
    systemd.sockets.plex-relay = {
      wantedBy = [ "sockets.target" ];
      requires = [ "nftables.service" ];
      after = [ "nftables.service" ];
      listenStreams = [ (toString plex.relayPort) ];
    };

    systemd.services.plex-relay.serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${plex.ip}:${toString plex.port}";
    };
  };
}
