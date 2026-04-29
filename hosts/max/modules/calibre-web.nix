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
    constants.services.calibreWeb.port
  ];

  virtualisation.oci-containers.containers.calibre-web = {
    image = "ghcr.io/linuxserver/calibre-web";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
      OAUTHLIB_RELAX_TOKEN_SCOPE = "1";
    };
    volumes = [
      "${constants.users.sandro.home}/calibre-web:/config"
      "${constants.mountPoints.books.path}:/books"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.calibreWeb.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-calibre-web = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.books.name}.mount"
      "nas-fetch-calibre-web.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "calibre-web";
        nfsMount = constants.mountPoints.configurations.path;
        source = "calibre-web";
        target = "${constants.users.sandro.home}/calibre-web";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "calibre-web";
        source = "${constants.users.sandro.home}/calibre-web";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "calibre-web";
        schedule = "daily";
      }
    ];
  };
}
