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
    image = "docker.io/gotson/komga:latest@sha256:c9ad2e0a0efdbb60a79b990836bd2b3d48b1f47677d2e5008579daa10a85e8e8";
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
