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
  homelab.oci-containers.chaptarr = {
    image = "docker.io/chaptarr/chaptarr:latest@sha256:9ab87a0bd01ffc3c59797061e2c240f81230bd5f3e1a92ddc52522945a719de2";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/chaptarr:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
      "${constants.mountPoints.books.path}:/books"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.chaptarr.ip}"
    ];
  };

  systemd.services.podman-chaptarr = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.downloads.name}.mount"
      "${constants.mountPoints.books.name}.mount"
      "nas-fetch-chaptarr-configs.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "chaptarr-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "chaptarr";
        target = "${constants.users.sandro.home}/chaptarr/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "chaptarr-configs";
        source = "${constants.users.sandro.home}/chaptarr/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "chaptarr";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
