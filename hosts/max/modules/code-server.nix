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
  homelab.oci-containers.code-server = {
    image = "lscr.io/linuxserver/code-server:latest@sha256:c84b35f6238af058e3543e2e9c0532c4d3d3902ef11effea3ed90e4ec293d46d";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.code-server-env.path
    ];
    environment = {
      DEFAULT_WORKSPACE = "${constants.users.sandro.home}/home-assistant";
    };
    volumes = [
      "${constants.users.sandro.home}/code-server:/config"
      "${constants.users.sandro.home}/home-assistant:${constants.users.sandro.home}/home-assistant"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.codeServer.ip}"
    ];
  };

  systemd.services.podman-code-server = {
    wantedBy = [ "multi-user.target" ];
    after = [ "create-podman-network-${constants.hosts.max.networkStack.name}.service" ];
  };
}

