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
      "/home/sandro/sonarr:/config"
      "/mnt/tv_shows:/tv"
      "/mnt/downloads:/downloads"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-sonarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-downloads.mount" "mnt-tv_shows.mount" "nas-fetch-sonarr-configs.service" "podman-create-network-media-stack.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "sonarr-configs";
        nfsMount = "/mnt/configurations";
        source = "sonarr";
        target = "/home/sandro/sonarr/Backups/";
        user = constants.users.alfred;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "sonarr-configs";
        source = "/home/sandro/sonarr/Backups/";
        nfsMount = "/mnt/configurations";
        destination = "sonarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
