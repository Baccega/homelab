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
      "/home/sandro/prowlarr:/config"
    ];
    networks = [ "media-stack" ];
  };

  systemd.services.podman-prowlarr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nas-sync-prowlarr-configs.service" "podman-create-network-media-stack.service" ];
  };

  services.nas-sync = {
    enable = true;
    syncPaths = [
      {
        name = "prowlarr-configs";
        nfsMount = "/mnt/configurations";
        source = "prowlarr";
        target = "/home/sandro/prowlarr/Backups/";
        user = constants.users.alfred;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "prowlarr-configs";
        source = "/home/sandro/prowlarr/Backups/";
        nfsMount = "/mnt/configurations";
        destination = "prowlarr";
        exclude = [ "logs/" ];
        schedule = "daily";
      }
    ];
  };
}
