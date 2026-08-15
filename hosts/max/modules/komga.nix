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
  homelab.oci-containers.komga = {
    image = "docker.io/gotson/komga:latest@sha256:6c2a967bbe9acefd05933b2eb498f34afe96a83c6f7f8ab0acb512a1bb3ab50f";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      SERVER_PORT = toString constants.services.komga.port;
    };
    volumes = [
      "${constants.users.sandro.home}/komga:/config"
      "${constants.mountPoints.books.path}:/data/books"
      "${constants.mountPoints.manga.path}:/data/manga"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.komga.ip}"
      "--user=${toString constants.users.alfred.uid}:${toString constants.groups.users}"
    ];
  };

  systemd.services.podman-komga = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.books.name}.mount"
      "${constants.mountPoints.manga.name}.mount"
      "nas-fetch-komga.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "komga";
        nfsMount = constants.mountPoints.configurations.path;
        source = "komga";
        target = "${constants.users.sandro.home}/komga";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "komga";
        source = "${constants.users.sandro.home}/komga";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "komga";
        exclude = [
          "/logs/"
          "/tmp/"
          "/cache/"
        ];
        schedule = "daily";
      }
    ];
  };
}
