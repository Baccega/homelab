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
  homelab.oci-containers.prowlarr = {
    image = "ghcr.io/linuxserver/prowlarr:latest@sha256:431d7efebcef466e56adaa40a7a2fa2b0e85159a037b8bf465eaadbf0cf5bedf";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/prowlarr:/config"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.prowlarr.ip}"
    ];
  };

  systemd.services.podman-prowlarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nas-fetch-prowlarr-configs.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" "podman-forward-proxy.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "prowlarr-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "prowlarr";
        target = "${constants.users.sandro.home}/prowlarr/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "prowlarr-configs";
        source = "${constants.users.sandro.home}/prowlarr/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "prowlarr";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
