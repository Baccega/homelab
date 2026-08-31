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
  homelab.oci-containers.qbittorrent = {
    image = "ghcr.io/linuxserver/qbittorrent:latest@sha256:a00b6a597a3832a1814cde0ef60abc55c94644f3f80902c3432f6af6de8d4a96";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/qbittorrent:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.qbittorrent.ip}"
    ];
  };

  systemd.services.podman-qbittorrent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "nas-fetch-qbittorrent-configs.service" "podman-forward-proxy.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "qbittorrent-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "qbittorrent";
        target = "${constants.users.sandro.home}/qbittorrent";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "qbittorrent-configs";
        source = "${constants.users.sandro.home}/qbittorrent";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "qbittorrent";
        exclude = [ "/qBittorrent/logs/" ];
        schedule = "daily";
      }
    ];
  };
}
