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
    image = "ghcr.io/home-assistant/home-assistant:stable@sha256:24e541ddae5818bf8eb27898b9ba00d0c344a655aa5097e9e9bd4b19356be847";
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

