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
  homelab.oci-containers.sonarr = {
    image = "ghcr.io/linuxserver/sonarr:latest@sha256:c19aa4ecdf03d73e1d5c901da33744cb7eb4d921f89bafed1ca264601d7fa224";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/sonarr:/config"
      "${constants.mountPoints.tv_shows.path}:/tv"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.sonarr.ip}"
    ];
  };

  systemd.services.podman-sonarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "${constants.mountPoints.tv_shows.name}.mount" "nas-fetch-sonarr-configs.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "sonarr-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "sonarr";
        target = "${constants.users.sandro.home}/sonarr/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "sonarr-configs";
        source = "${constants.users.sandro.home}/sonarr/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "sonarr";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
