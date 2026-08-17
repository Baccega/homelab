{ config, pkgs, lib, ... }:
let
  cfg = config.backup;

  statusDir = "/var/lib/backup-status";
  resticCacheDir = "/var/cache/restic";

  # Applied to every job, on top of job-specific `exclude`. restic uses
  # gitignore-style matching, so a bare name matches that file/dir anywhere.
  defaultExcludes = [
    ".bash_history"
    ".cache"
    ".Cache"
    "Cache"
    "cache"
    "caches"
    "tmp"
    "temp"
    "logs"
    "log"
    "*.log"
    "*.tmp"
    "*.swp"
    "*~"
    "lost+found"
    ".Trash"
    ".DS_Store"
    "Thumbs.db"
    "node_modules"
    "__pycache__"
    "*.pyc"
    ".esphome"
    "@eaDir"
  ];

  # Shared by backup jobs and the watchdog. No-op unless healthcheckUrl is set.
  pingHealthFn = ''
    ping_health() {
      local status="$1"
      local msg="$2"
      ${lib.optionalString (cfg.healthcheckUrl != null) ''
        ${pkgs.curl}/bin/curl -fsS -o /dev/null --max-time 10 -G "${cfg.healthcheckUrl}" \
          --data-urlencode "status=$status" \
          --data-urlencode "msg=$msg" \
          || echo "WARNING: healthcheck ping failed"
      ''}
    }
  '';

  passwordFileFor = nfsMount: "${nfsMount}/.restic-password";

  lightExcludes = [
    ".DS_Store"
    "Thumbs.db"
    "lost+found"
    "@eaDir"
  ];
in
{
  options.backup = {
    enable = lib.mkEnableOption "Enable backup service";

    healthcheckUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://uptime.example.com/api/push/TOKEN";
      description = ''
        Optional Uptime Kuma Push URL (or any HTTP heartbeat that accepts
        `status` and `msg` query params). One Push monitor covers every job
        on this host: the `msg` names which backup failed (for example
        `failed: n8n, postgres (stale)`). A watchdog pings `status=up` while
        every job has succeeded within 48 hours; a failed job immediately
        pings `status=down`. Beszel does not monitor systemd timers.
      '';
    };

    jobs = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Unique name for this backup job";
            example = "my-app-files-backup";
          };
          source = lib.mkOption {
            type = lib.types.str;
            description = "Source path to backup";
            example = "/home/sandro/app";
          };
          nfsMount = lib.mkOption {
            type = lib.types.str;
            description = "NFS mount point to use as base for destination";
            example = "/mnt/configurations";
          };
          destination = lib.mkOption {
            type = lib.types.str;
            description = "Destination path on NAS (relative to mounted NFS share). This directory becomes a restic repository.";
            example = "app";
          };
          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of patterns to exclude from backup (restic gitignore syntax)";
            example = [ "cache" "*.tmp" ".git" ];
          };
          appBackups = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Set when `source` is the app's own backup/dump folder (already
              versioned archives), not live config. Uses lighter excludes and
              longer restic retention so copies survive after the app rotates
              its local archives.
            '';
          };
          schedule = lib.mkOption {
            type = lib.types.str;
            default = "daily";
            description = "Backup schedule (daily, weekly, or custom systemd calendar)";
            example = "daily";
          };
          user = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "User to run the backup as";
          };
          group = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Group to run the backup as";
          };
          preBackupScript = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional script to run before backup";
          };
          postBackupScript = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional script to run after backup";
          };
        };
      });
      default = [];
      description = "Backup job configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ restic ];

    systemd.tmpfiles.rules = [
      "d ${statusDir} 0755 root root -"
      "d ${resticCacheDir} 0755 root root -"
    ] ++ lib.concatLists (map (jobConfig:
      let
        homeDir = if lib.hasPrefix "/home/" jobConfig.source then
          lib.head (lib.splitString "/" (lib.removePrefix "/home/" jobConfig.source))
        else null;
      in
      if homeDir != null then [
        "d /home/${homeDir} 0755 ${homeDir} ${toString jobConfig.group} -"
      ] else []
    ) cfg.jobs);

    systemd.services = lib.mkMerge [
      (lib.listToAttrs (map (jobConfig:
        let
          appBackups = jobConfig.appBackups;
          excludeFile = pkgs.writeText "backup-${jobConfig.name}-excludes.txt" (
            lib.concatStringsSep "\n" (
              (if appBackups then lightExcludes else defaultExcludes)
              ++ jobConfig.exclude
              ++ [ "" ]
            )
          );
          passwordFile = passwordFileFor jobConfig.nfsMount;
          repo = "${jobConfig.nfsMount}/${jobConfig.destination}";
          forgetArgs =
            if appBackups then
              # Cheap, already-consistent archives: keep them after the app
              # rotates its local copies.
              "--keep-daily 14 --keep-weekly 8 --keep-monthly 12"
            else
              "--keep-daily 7 --keep-weekly 4 --keep-monthly 6";
          snapshotTag = if appBackups then "app-backups" else "live-config";
        in {
          name = "backup-${jobConfig.name}";
          value = {
            description = "Backup job: ${jobConfig.name}";
            after = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" jobConfig.nfsMount}.mount" ];
            wants = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" jobConfig.nfsMount}.mount" ];

            serviceConfig = {
              Type = "oneshot";
              User = toString jobConfig.user;
              Group = toString jobConfig.group;
              Nice = 10;
              ExecStart = pkgs.writeShellScript "backup-${jobConfig.name}.sh" ''
                set -euo pipefail

                STATUS_FILE="${statusDir}/${jobConfig.name}"
                PASSWORD_FILE="${passwordFile}"
                REPO="${repo}"
                STATUS=fail

                export RESTIC_REPOSITORY="$REPO"
                export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
                export RESTIC_CACHE_DIR="${resticCacheDir}"
                export RESTIC_COMPRESSION="auto"

                RESTIC="${pkgs.restic}/bin/restic --retry-lock 10m"

                log() {
                  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
                }

                ${pingHealthFn}

                trap '
                  echo "$STATUS $(date +%s)" > "$STATUS_FILE"
                  if [ "$STATUS" != ok ]; then
                    ping_health down "failed: ${jobConfig.name}"
                  fi
                ' EXIT

                log "Starting backup job: ${jobConfig.name} (${snapshotTag})"

                if [ ! -e "${jobConfig.source}" ]; then
                  log "ERROR: Source path '${jobConfig.source}' does not exist"
                  exit 1
                fi

                if ! test -d "${jobConfig.nfsMount}"; then
                  log "ERROR: NFS mount directory ${jobConfig.nfsMount} does not exist"
                  exit 1
                fi

                mkdir -p "${resticCacheDir}" "${statusDir}"

                if [ ! -f "$PASSWORD_FILE" ]; then
                  log "Generating restic password at $PASSWORD_FILE"
                  umask 077
                  tmp=$(mktemp "$PASSWORD_FILE.XXXXXX")
                  ${pkgs.openssl}/bin/openssl rand -base64 32 > "$tmp"
                  mv -n "$tmp" "$PASSWORD_FILE" || true
                  rm -f "$tmp"
                  if [ ! -f "$PASSWORD_FILE" ]; then
                    log "ERROR: Could not create restic password file $PASSWORD_FILE"
                    exit 1
                  fi
                  chmod 600 "$PASSWORD_FILE" || true
                fi

                if [ -f "$REPO/config" ] && [ -d "$REPO/snapshots" ] && [ -d "$REPO/keys" ]; then
                  log "Using existing restic repository $REPO"
                else
                  if [ -e "$REPO" ] && [ "$(ls -A "$REPO" 2>/dev/null || true)" ]; then
                    legacy="$REPO.rsync-legacy"
                    log "Existing non-restic data found, moving aside to $legacy"
                    if [ -e "$legacy" ]; then
                      log "ERROR: Cannot migrate: $legacy already exists"
                      exit 1
                    fi
                    mv "$REPO" "$legacy"
                  fi
                  mkdir -p "$REPO"
                  log "Initializing restic repository at $REPO"
                  $RESTIC init
                fi

                ${lib.optionalString (jobConfig.preBackupScript != null) ''
                  log "Running pre-backup script"
                  ${jobConfig.preBackupScript}
                ''}

                log "Backing up ${jobConfig.source} to $REPO"
                $RESTIC backup \
                  --verbose \
                  --skip-if-unchanged \
                  ${lib.optionalString (!appBackups) "--exclude-caches"} \
                  --exclude-file "${excludeFile}" \
                  --tag "${snapshotTag}" \
                  "${jobConfig.source}"

                log "Forgetting old snapshots"
                $RESTIC forget ${forgetArgs} --prune

                ${lib.optionalString (jobConfig.postBackupScript != null) ''
                  log "Running post-backup script"
                  ${jobConfig.postBackupScript}
                ''}

                STATUS=ok
                log "Backup job finished successfully"
              '';
            };
          };
        }
      ) cfg.jobs))

      (lib.mkIf (cfg.jobs != []) {
        backup-watchdog = {
          description = "Report backup job health";
          after = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "backup-watchdog.sh" ''
              set -euo pipefail

              STALE_AFTER=172800
              now=$(date +%s)
              failed=""
              seen=0

              ${pingHealthFn}

              append_fail() {
                if [ -z "$failed" ]; then
                  failed="$1"
                else
                  failed="$failed, $1"
                fi
              }

              for name in ${lib.concatMapStringsSep " " (j: j.name) cfg.jobs}; do
                file="${statusDir}/$name"
                if [ ! -f "$file" ]; then
                  echo "No status yet for $name (not run since deploy)"
                  continue
                fi
                seen=$((seen + 1))
                read -r st ts _ < "$file" || true
                if [ "$st" != ok ]; then
                  echo "FAILED: $name (status=$st)"
                  append_fail "$name"
                  continue
                fi
                if [ -z "''${ts:-}" ] || [ $((now - ts)) -gt "$STALE_AFTER" ]; then
                  echo "STALE: $name (last ok $ts)"
                  append_fail "$name (stale)"
                else
                  echo "OK: $name"
                fi
              done

              if [ -n "$failed" ]; then
                ping_health down "failed: $failed"
                echo "ERROR: failed or stale backups: $failed"
                exit 1
              fi

              if [ "$seen" -eq 0 ]; then
                echo "No backup has completed yet; not reporting up"
                exit 0
              fi

              ping_health up "all backups ok"
              echo "All backups ok"
            '';
          };
        };
      })
    ];

    systemd.timers = lib.mkMerge [
      (lib.listToAttrs (map (jobConfig: {
        name = "backup-${jobConfig.name}";
        value = {
          description = "Timer for backup job: ${jobConfig.name}";
          wantedBy = [ "timers.target" ];
          timerConfig =
            let
              nightWindow = {
                RandomizedDelaySec = "3h";
                FixedRandomDelay = true;
                Persistent = true;
              };
            in
              if jobConfig.schedule == "daily" then nightWindow // {
                OnCalendar = "*-*-* 00:00:00";
              } else if jobConfig.schedule == "weekly" then nightWindow // {
                OnCalendar = "Sun *-*-* 00:00:00";
              } else nightWindow // {
                OnCalendar = jobConfig.schedule;
              };
        };
      }) cfg.jobs))

      (lib.mkIf (cfg.jobs != []) {
        backup-watchdog = {
          description = "Timer for backup health watchdog";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "hourly";
            Persistent = true;
            RandomizedDelaySec = "10m";
          };
        };
      })
    ];
  };
}
