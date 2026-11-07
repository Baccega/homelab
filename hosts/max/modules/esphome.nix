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
  homelab.oci-containers.esphome = {
    image = "ghcr.io/esphome/esphome:stable@sha256:4a918585150e95e7675be84a347384ff308fde1bd32d0e4472666e1252cc0e8f";
    volumes = [
      "${constants.users.sandro.home}/esphome:/config"
      "/dev:/dev"
      "/run/udev:/run/udev:ro"
    ];
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      # https://esphome.io/guides/faq/#docker-reference
    #   ESPHOME_DASHBOARD_USE_PING = "true";
    };
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.esphome.ip}"
      "--privileged"
    ];
  };

  systemd.services.podman-esphome = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-esphome.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "esphome";
        nfsMount = constants.mountPoints.configurations.path;
        source = "esphome";
        target = "${constants.users.sandro.home}/esphome";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "esphome";
        source = "${constants.users.sandro.home}/esphome";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "esphome";
        schedule = "daily";
      }
    ];
  };
}

