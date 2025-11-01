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
    constants.services.sabnzbd.port
  ];

  virtualisation.oci-containers.containers.sabnzbd = {
    image = "lscr.io/linuxserver/sabnzbd:latest";  
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/sabnzbd:/config"
      "${constants.mountPoints.downloads.path}:/downloads"
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.sabnzbd.ip}"
    ];
  };

  # Ensure container waits for NFS mount
  systemd.services.podman-sabnzbd = {
    wantedBy = [ "multi-user.target" ];
    after = [ "${constants.mountPoints.downloads.name}.mount" "nas-fetch-sabnzbd-configs.service" "podman-create-network-${constants.network.maxNetworkStack.name}.service" "podman-forward-proxy.service"];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "sabnzbd-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "sabnzbd";
        target = "${constants.users.sandro.home}/sabnzbd";
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
        source = "${constants.users.sandro.home}/sabnzbd";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "sabnzbd";
        exclude = [ "logs/" "downloads/" "Downloads/" ];
        schedule = "daily";
      }
    ];
  };

}

