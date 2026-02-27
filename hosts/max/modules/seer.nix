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
    constants.services.seer.port
  ];

  virtualisation.oci-containers.containers.seer = {
    image = "ghcr.io/seerr-team/seerr:latest";
    volumes = [
      "${constants.users.sandro.home}/seer:/app/config"
    ];
    environment = {
      PORT = toString constants.services.seer.port;
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.seer.ip}"
      "--label=io.containers.autoupdate=registry"
      "--init"
    ];
  };

  systemd.services.podman-seer = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-seer.service"
      "create-podman-network-${constants.network.maxNetworkStack.name}.service"
    ];
    preStart = ''
      mkdir -p ${constants.users.sandro.home}/seer
      chown ${constants.users.sandro.name}:${toString constants.groups.users} ${constants.users.sandro.home}/seer
      chmod 775 ${constants.users.sandro.home}/seer
    '';
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "seer";
        nfsMount = constants.mountPoints.configurations.path;
        source = "seer";
        target = "${constants.users.sandro.home}/seer";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "seer";
        source = "${constants.users.sandro.home}/seer";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "seer";
        schedule = "daily";
      }
    ];
  };
}
