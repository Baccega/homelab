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
  homelab.oci-containers.uptime-kuma = {
    image = "ghcr.io/louislam/uptime-kuma:2@sha256:3e24e96c89efff0e3a4b0698cbdd36c15ad3022371db57166e5588853002ee5c";
    volumes = [
      "${constants.users.sandro.home}/uptime-kuma:/app/data"
    ];
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.uptimeKuma.ip}"
    ];
  };

  systemd.services.podman-uptime-kuma = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-uptime-kuma.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "uptime-kuma";
        nfsMount = constants.mountPoints.configurations.path;
        source = "uptime-kuma";
        target = "${constants.users.sandro.home}/uptime-kuma";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "uptime-kuma";
        source = "${constants.users.sandro.home}/uptime-kuma";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "uptime-kuma";
        schedule = "daily";
      }
    ];
  };
}

