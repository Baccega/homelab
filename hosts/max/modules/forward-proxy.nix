{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
in
{
  networking.firewall.allowedTCPPorts = [ 
    constants.network.forwardProxy.port
  ];

  virtualisation.oci-containers.containers.forward-proxy = {
    image = "curve25519xsalsa20poly1305/openvpn:latest";
    ports = [
      "${toString constants.network.forwardProxy.port}:1080"
    ];
    volumes = [
      "${constants.users.sandro.home}/vpn:/vpn:ro"
    ];
    environment = {
      OPENVPN_CONFIG = "/vpn/ch-zur.prod.surfshark.comsurfshark_openvpn_udp.ovpn";
    };
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--device=/dev/net/tun"
      "--network=bridge"
    ];
  };

  # Ensure container starts before other services
  systemd.services.podman-forward-proxy = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nas-fetch-vpn-configs.service" ];
    requires = [ "network.target" "nas-fetch-vpn-configs.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "vpn-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "vpn";
        target = "${constants.users.sandro.home}/vpn";
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "vpn-configs";
        source = "${constants.users.sandro.home}/vpn";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "vpn";
        schedule = "daily";
      }
    ];
  };
}

