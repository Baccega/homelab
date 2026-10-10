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
  homelab.oci-containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable@sha256:1b64d38f38d922bf9d59336451fd6453e1d614f934456af4ee3d2a51061be3a4";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/home-assistant:/config"
      "/run/dbus:/run/dbus:ro"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.homeAssistant.ip}"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
    ];
  };

  systemd.services.podman-homeassistant = {
    wantedBy = [ "multi-user.target" ];
    after = [ "create-podman-network-${constants.hosts.max.networkStack.name}.service" "nas-fetch-home-assistant-configs.service" ];
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
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}

