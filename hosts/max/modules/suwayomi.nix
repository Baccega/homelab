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
    constants.services.suwayomi.port
  ];

  virtualisation.oci-containers.containers.suwayomi = {
    image = "ghcr.io/suwayomi/suwayomi-server:stable";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    environment = {
      BIND_IP = "0.0.0.0";
      BIND_PORT = toString constants.services.suwayomi.port;
      WEB_UI_ENABLED = "true";
      DOWNLOAD_AS_CBZ = "true";
      AUTO_DOWNLOAD_CHAPTERS = "true";
      AUTO_DOWNLOAD_EXCLUDE_UNREAD = "false";
    };
    volumes = [
      "${constants.mountPoints.manga.path}:/home/suwayomi/.local/share/Tachidesk/downloads"
      "${constants.users.sandro.home}/suwayomi:/home/suwayomi/.local/share/Tachidesk"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.suwayomi.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-suwayomi = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "${constants.mountPoints.manga.name}.mount"
      "nas-fetch-suwayomi.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "suwayomi";
        nfsMount = constants.mountPoints.configurations.path;
        source = "suwayomi";
        target = "${constants.users.sandro.home}/suwayomi";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "suwayomi";
        source = "${constants.users.sandro.home}/suwayomi";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "suwayomi";
        exclude = [
          "/downloads/"
          "/logs/"
          "/tmp/"
        ];
        schedule = "daily";
      }
    ];
  };
}
