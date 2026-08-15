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
    image = "ghcr.io/esphome/esphome:stable@sha256:e636269c6390c2124916510d45f55febb1d9ce41365f8445c9083ee41e43c92b";
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

