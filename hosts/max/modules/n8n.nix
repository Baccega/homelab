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
    image = "docker.n8n.io/n8nio/n8n";
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
    after = [ "create-podman-network-${constants.network.maxNetworkStack.name}.service" ];
  };
}

