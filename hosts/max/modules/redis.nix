# Redis on Max
# Runs on the shared ipvlan network so services can reach it by IP. Redis only
# holds Paperless' task queue/cache, so it is not critical, but a daily RDB
# snapshot is still synced to the NAS over NFS for completeness.
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
    image = "docker.io/library/redis:8@sha256:344e3945a0b431c8ff1eecd58c5573538126bd756f02fc7e218ddf1fc2546366";
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
