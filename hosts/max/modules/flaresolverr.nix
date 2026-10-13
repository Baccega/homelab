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
  homelab.oci-containers.flaresolverr = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest@sha256:c80ae007ce2ccdcd217a12426e4f039ef763ff90738c808d38810c3e59323767";
    environment = {
      LOG_LEVEL = "info";
      PROXY_URL = "socks5://${constants.services.forwardProxy.ip}:${toString constants.services.forwardProxy.port}";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.flaresolverr.ip}"
    ];
  };

  systemd.services.podman-flaresolverr = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
      "podman-forward-proxy.service"
    ];
  };
}
