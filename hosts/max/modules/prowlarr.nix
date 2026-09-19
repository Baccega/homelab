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
  homelab.oci-containers.prowlarr = {
    image = "ghcr.io/linuxserver/prowlarr:latest@sha256:c96b56d94d116a9f4de94bc23d3381689492e6c3cfb7435320e8d982e406f99a";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/prowlarr:/config"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.prowlarr.ip}"
    ];
  };

  systemd.services.podman-prowlarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nas-fetch-prowlarr-configs.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" "podman-forward-proxy.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "prowlarr-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "prowlarr";
        target = "${constants.users.sandro.home}/prowlarr/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "prowlarr-configs";
        source = "${constants.users.sandro.home}/prowlarr/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "prowlarr";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
