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
  networking.firewall.allowedTCPPorts = [ 
    constants.services.sonarr.port
  ];

  virtualisation.oci-containers.containers.sonarr = {
    image = "ghcr.io/linuxserver/sonarr";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    ports = [
      "${toString constants.services.sonarr.port}:8989"
    ];
    volumes = [
      "${constants.users.sandro.home}/sonarr:/config"
      "${constants.mountPoints.tv_shows.path}:/tv"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-sonarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "${constants.mountPoints.tv_shows.name}.mount" "nas-fetch-sonarr-configs.service" "podman-create-network-media-stack.service" ];
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
        source = "${constants.users.sandro.home}/sonarr/Backups/";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "sonarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
