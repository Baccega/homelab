# PostgreSQL on Max
# Runs on the shared ipvlan network so services can reach it by IP. The live
# data directory is intentionally not rsynced as-is; instead a daily pg_dump is
# written to a dumps directory which is what gets backed up to the NAS over NFS
# (a logical dump is consistent and safe to restore, unlike copying live files).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/postgres/data";
  dumpsDir = "${constants.users.sandro.home}/postgres/dumps";
in
{
  # Ensure the dumps directory exists before the backup job's source check runs.
  systemd.tmpfiles.rules = [
    "d ${constants.users.sandro.home}/postgres 0750 root root -"
    "d ${dumpsDir} 0750 root root -"
  ];

  virtualisation.oci-containers.containers.postgres = {
    image = "docker.io/library/postgres:18";
    environment = {
      POSTGRES_DB = "paperless";
      POSTGRES_USER = "paperless";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.postgres-env.path
    ];
    # postgres:18 moved its VOLUME to /var/lib/postgresql (PGDATA is
    # /var/lib/postgresql/18/docker), so the bind mount targets that path.
    volumes = [
      "${dataDir}:/var/lib/postgresql"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.postgres.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-postgres = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "postgres";
        # The dumps directory is the backup source; the dump itself is produced
        # by the pre-backup script below.
        source = dumpsDir;
        nfsMount = constants.mountPoints.configurations.path;
        destination = "postgres";
        schedule = "daily";
        preBackupScript = ''
          ${pkgs.podman}/bin/podman exec postgres sh -c \
            'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h 127.0.0.1 -U paperless -d paperless -F c' \
            > "${dumpsDir}/paperless.dump"
        '';
      }
    ];
  };
}
