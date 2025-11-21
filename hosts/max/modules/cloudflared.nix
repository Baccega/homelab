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
  virtualisation.oci-containers.containers.cloudflared = {
    image = "docker.io/cloudflare/cloudflared:latest";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.cloudflared-token.path
    ];
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.cloudflared.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-cloudflared = {
    wantedBy = [ "multi-user.target" ];
    after = [ "create-podman-network-${constants.network.maxNetworkStack.name}.service" ];
  };
}

