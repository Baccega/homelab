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
    constants.services.qbittorrent.port
    constants.services.qbittorrent.torrentPort
  ];

  virtualisation.oci-containers.containers.qbittorrent = {
    image = "ghcr.io/linuxserver/qbittorrent";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    ports = [
      "${toString constants.services.qbittorrent.port}:8080"
      "${toString constants.services.qbittorrent.torrentPort}:6881"
      "${toString constants.services.qbittorrent.torrentPort}:6881/udp"
    ];
    volumes = [
      "/home/sandro/qbittorrent:/config"
      "/mnt/downloads:/downloads"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-qbittorrent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-downloads.mount" "nas-fetch-qbittorrent-configs.service" "podman-create-network-media-stack.service"  ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "qbittorrent-configs";
        nfsMount = "/mnt/configurations";
        source = "qbittorrent";
        target = "/home/sandro/qbittorrent";
        user = constants.users.alfred;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "qbittorrent-configs";
        source = "/home/sandro/qbittorrent";
        nfsMount = "/mnt/configurations";
        destination = "qbittorrent";
        exclude = [ "qBittorrent/logs/" ];
        schedule = "daily";
      }
    ];
  };
}
