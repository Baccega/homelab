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
    image = "ghcr.io/pennydreadful/bookshelf:hardcover@sha256:388eecc94362580eae31ee0a454be6af516f8a311f8432a521c202fb475f4359";
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
        schedule = "daily";
      }
    ];
  };
}
