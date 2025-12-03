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
    constants.services.uptimeKuma.port
  ];

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "ghcr.io/louislam/uptime-kuma:2";
    volumes = [
      "${constants.users.sandro.home}/uptime-kuma:/app/data"
    ];
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.uptimeKuma.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-uptime-kuma = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-uptime-kuma.service"
      "create-podman-network-${constants.network.maxNetworkStack.name}.service"
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

