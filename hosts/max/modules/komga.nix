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
    image = "docker.io/gotson/komga:latest@sha256:341f1e7dbd48a42f4df7d0af40f7a6644d7db0b2ed6ea8cbc8c0ccaa71e48b66";
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
