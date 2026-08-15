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
    image = "ghcr.io/louislam/uptime-kuma:2@sha256:a8610b3b4c38077922ba51b036691e06887d7cefd91fe620fd3d6d23d03dc240";
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

