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
  homelab.oci-containers.n8n = {
    image = "docker.io/n8nio/n8n:next@sha256:97ce2e6bd5d7e4ff7c38620dde28f9465d8af3970463dd65f2546b56f1a3df25";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/n8n:/home/node/.n8n"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.n8n.ip}"
    ];
  };

  systemd.services.podman-n8n = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-n8n.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "n8n";
        nfsMount = constants.mountPoints.configurations.path;
        source = "n8n";
        target = "${constants.users.sandro.home}/n8n";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "n8n";
        source = "${constants.users.sandro.home}/n8n";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "n8n";
        schedule = "daily";
      }
    ];
  };
}

