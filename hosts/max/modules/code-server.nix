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
    image = "lscr.io/linuxserver/code-server:latest@sha256:4524d0b00478e41264f42e0e660c1819e3b7d0c460f78ce73e44fa39b2b55134";
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

