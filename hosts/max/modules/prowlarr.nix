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
    constants.services.prowlarr.port
  ];

  virtualisation.oci-containers.containers.prowlarr = {
    image = "ghcr.io/linuxserver/prowlarr";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    ports = [
      "${toString constants.services.prowlarr.port}:9696"
    ];
    volumes = [
      "${constants.users.sandro.home}/prowlarr:/config"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-prowlarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nas-fetch-prowlarr-configs.service" "podman-create-network-media-stack.service" ];
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
        source = "${constants.users.sandro.home}/prowlarr/Backups/";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "prowlarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
