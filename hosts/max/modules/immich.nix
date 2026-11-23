# Immich on Max. PostgreSQL and Redis are shared with other Max services.
{
  config,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/immich";
  network = constants.hosts.max.networkStack.name;
  networkUnit = "create-podman-network-${network}.service";
  nfsMount = constants.mountPoints.configurations.path;
  sharedPhotos = "/mnt/hachiko-photos-shared";
in
{
  homelab.oci-containers.immich = {
    image = "ghcr.io/immich-app/immich-server:v3.4.2@sha256:fc880c1bf665b4aab1e74c15e56ab871225989cd546536e6b77e771869af06bd";
    dependsOn = [ "postgres" "redis" "immich-machine-learning" ];
    environment = {
      DB_HOSTNAME = constants.services.postgres.ip;
      DB_PORT = toString constants.services.postgres.port;
      DB_USERNAME = "immich";
      DB_DATABASE_NAME = "immich";
      DB_VECTOR_EXTENSION = "pgvector";
      REDIS_HOSTNAME = constants.services.redis.ip;
      REDIS_PORT = toString constants.services.redis.port;
      REDIS_DBINDEX = "1";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.redis-env.path
      config.sops.secrets.immich-env.path
    ];
    volumes = [
      "${dataDir}/media:/data"
      "${sharedPhotos}:/external/shared:ro"
    ];
    networks = [ network ];
    extraOptions = [
      "--ip=${constants.services.immich.ip}"
      # Keep the upstream ML URL working on ipvlan, which has no container DNS.
      "--add-host=immich-machine-learning:${constants.services.immichMachineLearning.ip}"
    ];
  };

  homelab.oci-containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v3.4.2@sha256:739405742a79bd7447227c553bb62ed5491aa36acf00bc667af7f9c93b6fae91";
    environment.MACHINE_LEARNING_MODEL_REVISION = "v2";
    volumes = [
      "${dataDir}/cache:/cache"
    ];
    networks = [ network ];
    extraOptions = [
      "--ip=${constants.services.immichMachineLearning.ip}"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 root root -"
    "d ${dataDir}/media 0700 root root -"
    "d ${dataDir}/cache 0700 root root -"
  ];

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig.Options = "ro,noatime,nfsvers=4";
      what = "${constants.hosts.hachiko.ip}:/volume2/photo";
      where = sharedPhotos;
    }
  ];

  systemd.services.podman-immich = {
    after = [ "sops-nix.service" networkUnit ];
    requires = [ networkUnit ];
    unitConfig = {
      RequiresMountsFor = sharedPhotos;
      AssertPathIsMountPoint = sharedPhotos;
    };
  };

  systemd.services.podman-immich-machine-learning = {
    after = [ networkUnit ];
    requires = [ networkUnit ];
  };

  systemd.services.backup-immich.unitConfig = {
    RequiresMountsFor = nfsMount;
    AssertPathIsMountPoint = nfsMount;
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "immich";
        source = dataDir;
        nfsMount = nfsMount;
        destination = "immich";
        schedule = "daily";
        # Capture the shared database before restic reads the media files.
        preBackupScript = ''
          umask 077
          dump=$(mktemp "${dataDir}/immich.dump.XXXXXX.tmp")
          if ! ${pkgs.podman}/bin/podman exec postgres sh -c \
            'PGPASSWORD="$POSTGRES_PASSWORD" exec pg_dump -h 127.0.0.1 -U paperless -d immich -Fc' > "$dump"; then
            rm "$dump"
            exit 1
          fi
          mv "$dump" "${dataDir}/immich.dump"
        '';
      }
    ];
  };
}
