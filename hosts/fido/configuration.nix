{ ... }:
let
  constants = import ../../constants.nix;
  relay = toString constants.services.plex.relayPort;
  hostname = "${constants.services.plex.subdomain}.${constants.network.publicDomain}";
in
{
  networking.hostName = "fido";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--accept-dns=false" "--accept-routes=false" ];
    extraSetFlags = [ "--accept-dns=false" "--accept-routes=false" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${hostname}.extraConfig = ''
      reverse_proxy ${constants.hosts.nemo.tailscaleIp}:${relay}
    '';
  };
}
