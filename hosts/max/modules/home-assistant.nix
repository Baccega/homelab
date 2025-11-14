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
    constants.services.homeAssistant.port
  ];

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/home-assistant:/config"
      "/run/dbus:/run/dbus:ro"
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.homeAssistant.ip}"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
    ];
  };

  systemd.services.podman-homeassistant = {
    wantedBy = [ "multi-user.target" ];
    after = [ "podman-create-network-${constants.network.maxNetworkStack.name}.service" "nas-fetch-home-assistant-configs.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "home-assistant-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "home-assistant";
        target = "${constants.users.sandro.home}/home-assistant/backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "home-assistant-configs";
        source = "${constants.users.sandro.home}/home-assistant/backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "home-assistant";
        schedule = "daily";
      }
    ];
  };
}

