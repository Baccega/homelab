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
  homelab.oci-containers.bookshelf = {
    image = "ghcr.io/pennydreadful/bookshelf:hardcover@sha256:67498dd5ece516867d72ee642abd6c1a66b36a135c8f7da0127109564372beb1";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/bookshelf:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
      "${constants.mountPoints.books.path}:/books"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.bookshelf.ip}"
    ];
  };

  systemd.services.podman-bookshelf = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.downloads.name}.mount"
      "${constants.mountPoints.books.name}.mount"
      "nas-fetch-bookshelf-configs.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "bookshelf-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "bookshelf";
        target = "${constants.users.sandro.home}/bookshelf/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "bookshelf-configs";
        source = "${constants.users.sandro.home}/bookshelf/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "bookshelf";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
