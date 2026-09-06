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
  homelab.oci-containers.forward-proxy = {
    image = "docker.io/qmcgaw/gluetun:latest@sha256:89e3cbe22e0d6f09a18d3e86269392fd9f7f08e8991040741e577f8f127cdfe4";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.forward-proxy-env.path
    ];
    environment = {
      SOCKS5_ENABLED = "on";
      SOCKS5_LISTENING_ADDRESS = ":${toString constants.services.forwardProxy.port}";
    };
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--device=/dev/net/tun"
      "--ip=${constants.services.forwardProxy.ip}"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
  };

  # Ensure container starts before other services
  systemd.services.podman-forward-proxy = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = "30s";
    };
  };
}

