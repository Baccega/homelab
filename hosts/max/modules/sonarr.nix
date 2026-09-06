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
    image = "ghcr.io/linuxserver/sonarr:latest@sha256:4d9df314875e1249ab7d6170c2b9b3dc1d8e6383f168ceb10dc9a5ad9b324739";
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
