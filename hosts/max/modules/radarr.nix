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
  homelab.oci-containers.radarr = {
    image = "ghcr.io/linuxserver/radarr:latest@sha256:51a9ac2a9eb47afc833541e5fd6c11b86eb9f810694c22fa2429e3078e9194b2";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/radarr:/config"
      "${constants.mountPoints.movies.path}:/movies"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.radarr.ip}"
    ];
  };

  systemd.services.podman-radarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "${constants.mountPoints.movies.name}.mount" "nas-fetch-radarr-configs.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "radarr-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "radarr";
        target = "${constants.users.sandro.home}/radarr/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "radarr-configs";
        source = "${constants.users.sandro.home}/radarr/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "radarr";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
