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
  homelab.oci-containers.plex = {
    image = "ghcr.io/linuxserver/plex:latest@sha256:d5ee6068a20ae57f95060038eaef292cdfd4285efb213ea4daaccdc184e45d1b";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      VERSION = "docker";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
      LD_LIBRARY_PATH = "/usr/local/nvidia/lib64:/usr/local/nvidia/lib";
    };
    volumes = [
      "${constants.users.sandro.home}/plex:/config"
      "${constants.mountPoints.tv_shows.path}:/tv"
      "${constants.mountPoints.movies.path}:/movies"
      "${constants.mountPoints.videocassette.path}:/videocassette"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
      "--ip=${constants.services.plex.ip}"
    ];
  };

  systemd.services.podman-plex = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.tv_shows.name}.mount"
      "${constants.mountPoints.movies.name}.mount"
      "${constants.mountPoints.videocassette.name}.mount"
      "nas-fetch-plex-configs.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
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
          "/Library/Application Support/Plex Media Server/Cache/"
          "/Library/Application Support/Plex Media Server/Logs/"
          "/Library/Application Support/Plex Media Server/Updates/"
          "/Library/Application Support/Plex Media Server/Crash Reports/"
          "/Library/Application Support/Plex Media Server/Diagnostics/"
        ];
        schedule = "daily";
      }
    ];
  };
}


