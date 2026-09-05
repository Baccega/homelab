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
  homelab.oci-containers.sabnzbd = {
    image = "lscr.io/linuxserver/sabnzbd:latest@sha256:64c4c2b6ed546237451cbfec33aa8bac1396865c1a266dd247c02b36ffe27c62";  
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/sabnzbd:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.sabnzbd.ip}"
    ];
  };

  # Ensure container waits for NFS mount
  systemd.services.podman-sabnzbd = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "nas-fetch-sabnzbd-configs.service" "create-podman-network-${constants.hosts.max.networkStack.name}.service" "podman-forward-proxy.service"];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "sabnzbd-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "sabnzbd";
        target = "${constants.users.sandro.home}/sabnzbd/backups";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "sabnzbd-configs";
        source = "${constants.users.sandro.home}/sabnzbd/backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "sabnzbd";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };

}

