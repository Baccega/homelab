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
      "${constants.users.sandro.home}/radarr:/config"
      "${constants.mountPoints.movies.path}:/movies"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-radarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "${constants.mountPoints.movies.name}.mount" "nas-fetch-radarr-configs.service" "podman-create-network-media-stack.service" ];
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
        source = "${constants.users.sandro.home}/radarr/Backups/";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "radarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
