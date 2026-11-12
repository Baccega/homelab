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
    image = "ghcr.io/linuxserver/qbittorrent:latest@sha256:3d4c4545d51a690a0df15a2ff99038823a88a9822df8e794526447b9afbd7384";
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
