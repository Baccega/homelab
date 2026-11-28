# Redis on Max
# Shared IPvlan service for Paperless and Immich queues and caches.
# A daily RDB snapshot is backed up to the NAS.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/redis/data";
in
{
  homelab.oci-containers.redis = {
    image = "docker.io/library/redis:8@sha256:56a1737794e36c3ebe8a4544a8ab421af3ab1a6488fb2238aec228c404933fed";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.redis-env.path
    ];
    cmd = [
      "sh"
      "-c"
      "exec redis-server --requirepass \"$REDIS_PASSWORD\""
    ];
    volumes = [
      "${dataDir}:/data"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.redis.ip}"
      "--user=${toString constants.users.alfred.uid}:${toString constants.groups.users}"
    ];
  };

  systemd.services.podman-redis = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-redis.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "redis";
        nfsMount = constants.mountPoints.configurations.path;
        source = "redis";
        target = dataDir;
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "redis";
        source = dataDir;
        nfsMount = constants.mountPoints.configurations.path;
        destination = "redis";
        schedule = "daily";
        # Force a synchronous snapshot so the copied dump.rdb is current.
        preBackupScript = ''
          ${pkgs.podman}/bin/podman exec redis sh -c \
            'redis-cli -a "$REDIS_PASSWORD" SAVE'
        '';
      }
    ];
  };
}
