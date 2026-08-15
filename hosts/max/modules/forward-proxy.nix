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
  virtualisation.oci-containers.containers.forward-proxy = {
    image = "docker.io/qmcgaw/gluetun:latest";
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
      "--label=io.containers.autoupdate=registry"
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

