{ lib, pkgs, ... }:
let
  constants = import ../../../constants.nix;
  service = constants.services.immich;
  version = "v3.4.1";
  privateNetwork = "immich-private";
  lanNetwork = constants.hosts.max.networkStack.name;
  state = "/var/lib/immich";
  backupDir = "${state}/backup";
  media = "${backupDir}/media";
  passwordFile = "${state}/credentials/db-password";
  nas = constants.mountPoints.configurations.path;
  podman = "${pkgs.podman}/bin/podman";
in
{
  systemd.tmpfiles.rules = [
    "d ${state} 0700 root root -"
    "d ${backupDir} 0700 root root -"
    "d ${media} 0700 root root -"
    "d ${state}/postgres 0700 root root -"
    "d ${state}/models 0700 root root -"
  ];

  systemd.services = {
    immich-setup = {
      description = "Prepare the Immich private network and database password";
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "immich/credentials";
        StateDirectoryMode = "0700";
      };
      script = ''
        set -eu
        umask 077
        if [ ! -s "${passwordFile}" ]; then
          if [ -e "${state}/postgres/PG_VERSION" ]; then
            echo "Restore the existing Immich database password before starting."
            exit 1
          fi
          tmp=$(mktemp "${passwordFile}.XXXXXX")
          trap 'rm -f "$tmp"' EXIT
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "$tmp"
          mv "$tmp" "${passwordFile}"
        fi
        if ! ${podman} network exists ${privateNetwork}; then
          ${podman} network create ${privateNetwork}
        fi
      '';
    };

    podman-immich-server = {
      requires = [ "immich-setup.service" "create-podman-network-${lanNetwork}.service" ];
      after = [ "immich-setup.service" "create-podman-network-${lanNetwork}.service" ];
    };
    backup-immich = {
      unitConfig = {
        RequiresMountsFor = nas;
        AssertPathIsMountPoint = nas;
      };
    };
  } // lib.genAttrs [ "podman-immich-postgres" "podman-immich-valkey" "podman-immich-machine-learning" ] (_: {
    requires = [ "immich-setup.service" ];
    after = [ "immich-setup.service" ];
  });

  homelab.oci-containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${version}@sha256:7c489add298fc2f92cda4c777de6462aa206877e04087b815f62c7664af0b53b";
      dependsOn = [ "immich-postgres" "immich-valkey" "immich-machine-learning" ];
      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_DATABASE_NAME = "immich";
        DB_PASSWORD_FILE = "/run/immich/db-password";
        DB_VECTOR_EXTENSION = "vectorchord";
        REDIS_HOSTNAME = "immich-valkey";
      };
      volumes = [
        "${media}:/data"
        "${passwordFile}:/run/immich/db-password:ro"
      ];
      networks = [ "${lanNetwork}:ip=${service.ip}" privateNetwork ];
    };

    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        POSTGRES_PASSWORD_FILE = "/run/immich/db-password";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      volumes = [
        "${state}/postgres:/var/lib/postgresql/data"
        "${passwordFile}:/run/immich/db-password:ro"
      ];
      networks = [ privateNetwork ];
      extraOptions = [ "--shm-size=128m" ];
    };

    immich-valkey = {
      image = "docker.io/valkey/valkey:9@sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd";
      networks = [ privateNetwork ];
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}@sha256:8adebf414256f6e4f837bfbb66fa94f4da7260e3a1d65cbba49e4e35d8764";
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
          if ! ${podman} exec immich-postgres pg_dump -U immich -d immich -Fc > "$dump"; then
            rm -f "$dump"
            exit 1
          fi
          mv "$dump" "${backupDir}/immich.dump"
        '';
      }
    ];
  };
}
