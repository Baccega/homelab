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
    image = "docker.io/qmcgaw/gluetun:latest@sha256:c2ee4191762fca6b6a3c3359a731198a95d9c9af4db32d466e223bf3a84e779b";
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

