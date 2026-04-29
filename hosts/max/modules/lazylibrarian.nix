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
  networking.firewall.allowedTCPPorts = [
    constants.services.lazylibrarian.port
  ];

  virtualisation.oci-containers.containers.lazylibrarian = {
    image = "ghcr.io/linuxserver/lazylibrarian";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    volumes = [
      "${constants.users.sandro.home}/lazylibrarian:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
      "${constants.mountPoints.books.path}:/books"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.lazylibrarian.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-lazylibrarian = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.downloads.name}.mount"
      "${constants.mountPoints.books.name}.mount"
      "nas-fetch-lazylibrarian.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "lazylibrarian";
        nfsMount = constants.mountPoints.configurations.path;
        source = "lazylibrarian";
        target = "${constants.users.sandro.home}/lazylibrarian";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "lazylibrarian";
        source = "${constants.users.sandro.home}/lazylibrarian";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "lazylibrarian";
        exclude = [
          "/logs/"
          "/cache/"
        ];
        schedule = "daily";
      }
    ];
  };
}
