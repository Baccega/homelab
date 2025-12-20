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
    constants.services.n8n.port
  ];

  virtualisation.oci-containers.containers.n8n = {
    image = "docker.io/n8nio/n8n:next";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/n8n:/home/node/.n8n"
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.n8n.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-n8n = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-n8n.service"
      "create-podman-network-${constants.network.maxNetworkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "n8n";
        nfsMount = constants.mountPoints.configurations.path;
        source = "n8n";
        target = "${constants.users.sandro.home}/n8n";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "n8n";
        source = "${constants.users.sandro.home}/n8n";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "n8n";
        schedule = "daily";
      }
    ];
  };
}

