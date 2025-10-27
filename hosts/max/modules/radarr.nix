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
    constants.services.radarr.port
  ];

  virtualisation.oci-containers.containers.radarr = {
    image = "ghcr.io/linuxserver/radarr";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    ports = [
      "${toString constants.services.radarr.port}:7878"
    ];
    volumes = [
      "/home/sandro/radarr:/config"
      "/mnt/movies:/movies"
      "/mnt/downloads:/downloads"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-radarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-downloads.mount" "mnt-movies.mount" "nas-sync-radarr-configs.service" "podman-create-network-media-stack.service" ];
  };

  services.nas-sync = {
    enable = true;
    syncPaths = [
      {
        name = "radarr-configs";
        nfsMount = "/mnt/configurations";
        source = "radarr";
        target = "/home/sandro/radarr/Backups/";
        user = constants.users.alfred;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "radarr-configs";
        source = "/home/sandro/radarr/Backups/";
        nfsMount = "/mnt/configurations";
        destination = "radarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
