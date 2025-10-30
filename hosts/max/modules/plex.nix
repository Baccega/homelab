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
    32400
    8324
    32469
  ];

  networking.firewall.allowedUDPPorts = [
    1900
    5353
    32410
    32412
    32413
    32414
  ];

  virtualisation.oci-containers.containers.plex = {
    image = "ghcr.io/linuxserver/plex";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      VERSION = "docker";
    };
    ports = [
      "32400:32400"
      "8324:8324"
      "32469:32469"
      "1900:1900/udp"
      "5353:5353/udp"
      "32410:32410/udp"
      "32412:32412/udp"
      "32413:32413/udp"
      "32414:32414/udp"
    ];
    volumes = [
      "${constants.users.sandro.home}/plex:/config"
      "${constants.mountPoints.tv_shows.path}:/tv"
      "${constants.mountPoints.movies.path}:/movies"
      "${constants.mountPoints.videocassette.path}:/videocassette"
    ];
    networks = [ "media-stack" ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
  };

  systemd.services.podman-plex = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.tv_shows.name}.mount"
      "${constants.mountPoints.movies.name}.mount"
      "${constants.mountPoints.videocassette.name}.mount"
      "nas-fetch-plex-configs.service"
      "podman-create-network-media-stack.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "plex-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "plex";
        target = "${constants.users.sandro.home}/plex";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "plex-configs";
        source = "${constants.users.sandro.home}/plex";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "plex";
        exclude = [ 
          "Library/Application Support/Plex Media Server/Cache"
          "Library/Application Support/Plex Media Server/Logs"
          "Library/Application Support/Plex Media Server/Updates"
          "Library/Application Support/Plex Media Server/Crash Reports"
          "Library/Application Support/Plex Media Server/Diagnostics"
        ];
        schedule = "daily";
      }
    ];
  };
}


