{ config, pkgs, ... }:
let
  constants = import ../../../constants.nix;
  service = constants.services.immich;
  version = "v3.4.1";
  privateNetwork = "immich-private";
  lanNetwork = constants.hosts.max.networkStack.name;
  state = "/var/lib/immich";
  backupDir = "${state}/backup";
  media = "${backupDir}/media";
  passwordFile = "/etc/immich/db-password";
  nas = constants.mountPoints.configurations.path;
  podman = "${pkgs.podman}/bin/podman";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 root root -"
    "d ${backupDir} 0700 root root -"
    "d ${media} 0700 root root -"
    "d ${state}/models 0700 root root -"
  ];

  systemd.services = {
    immich-setup = {
      description = "Prepare the Immich machine-learning network";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu
        if ! ${podman} network exists ${privateNetwork}; then
          ${podman} network create ${privateNetwork}
        fi
      '';
    };

    podman-immich-server = {
      unitConfig.ConditionPathExists = passwordFile;
      requires = [ "immich-setup.service" "create-podman-network-${lanNetwork}.service" ];
      after = [ "immich-setup.service" "create-podman-network-${lanNetwork}.service" "sops-nix.service" ];
    };
    backup-immich = {
      unitConfig = {
        RequiresMountsFor = nas;
        AssertPathIsMountPoint = nas;
      };
    };
    podman-immich-machine-learning = {
      requires = [ "immich-setup.service" ];
      after = [ "immich-setup.service" ];
    };
  };

  homelab.oci-containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${version}@sha256:7c489add298fc2f92cda4c777de6462aa206877e04087b815f62c7664af0b53b";
      dependsOn = [ "postgres" "redis" "immich-machine-learning" ];
      environmentFiles = [ config.sops.secrets.redis-env.path ];
      environment = {
        DB_HOSTNAME = constants.services.postgres.ip;
        DB_PORT = toString constants.services.postgres.port;
        DB_USERNAME = "immich";
        DB_DATABASE_NAME = "immich";
        DB_PASSWORD_FILE = "/run/immich/db-password";
        DB_VECTOR_EXTENSION = "pgvector";
        REDIS_HOSTNAME = constants.services.redis.ip;
        REDIS_PORT = toString constants.services.redis.port;
        REDIS_DBINDEX = "1";
      };
      volumes = [
        "${media}:/data"
        "${passwordFile}:/run/immich/db-password:ro"
      ];
      networks = [ "${lanNetwork}:ip=${service.ip}" privateNetwork ];
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}@sha256:8adebf414256f6e4f837bfbb66fa94f14f4da7260e3a1d65cbba49e4e35d8764";
      environment.MACHINE_LEARNING_MODEL_REVISION = "v2";
      volumes = [ "${state}/models:/cache" ];
      networks = [ privateNetwork ];
    };
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "immich";
        source = backupDir;
        nfsMount = nas;
        destination = "immich";
        schedule = "daily";
        preBackupScript = ''
          umask 077
          dump=$(mktemp "${backupDir}/immich.dump.XXXXXX.tmp")
          if ! ${podman} exec postgres sh -c \
            'PGPASSWORD="$POSTGRES_PASSWORD" exec pg_dump -h 127.0.0.1 -U paperless -d immich -Fc' > "$dump"; then
            rm -f "$dump"
            exit 1
          fi
          mv "$dump" "${backupDir}/immich.dump"
        '';
      }
    ];
  };
}
