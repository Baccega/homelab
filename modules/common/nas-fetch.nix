{ config, pkgs, lib, ... }:
let
  constants = import ../../constants.nix;
in
{
  options.services.nas-fetch = {
    enable = lib.mkEnableOption "NAS sync service";

    syncPaths = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Unique name for this sync operation";
          };
          nfsMount = lib.mkOption {
            type = lib.types.str;
            description = "NFS mount point to use as base";
            example = "/mnt/configurations";
          };
          source = lib.mkOption {
            type = lib.types.str;
            description = "Source path on NAS (relative to mounted NFS share)";
            example = "/my-app";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Target local path";
            example = "/home/sandro/my-app";
          };
          user = lib.mkOption {
            type = lib.types.int;
            description = "User to own the synced files";
            default = constants.users.alfred.uid;
          };
          group = lib.mkOption {
            type = lib.types.int;
            description = "Group to own the synced files";
            default = constants.groups.users;
          };
          mode = lib.mkOption {
            type = lib.types.str;
            description = "File mode for synced files";
            default = "755";
          };
        };
      });
      description = "List of paths to sync from NAS";
      default = [];
    };
  };

  config = lib.mkIf config.services.nas-fetch.enable {
    environment.systemPackages = with pkgs; [ restic rsync jq ];

    systemd.tmpfiles.rules = [
      "d /var/cache/restic 0755 root root -"
    ];

    systemd.services = lib.listToAttrs (map (syncPath: {
      name = "nas-fetch-${syncPath.name}";
      value = {
        description = "Sync ${syncPath.name} from NAS";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" syncPath.nfsMount}.mount" ];
        requires = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" syncPath.nfsMount}.mount" ];

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = pkgs.writeShellScript "nas-fetch-${syncPath.name}.sh" ''
            set -euo pipefail

            SOURCE="${syncPath.nfsMount}/${syncPath.source}"
            TARGET="${syncPath.target}"
            PASSWORD_FILE="${syncPath.nfsMount}/.restic-password"
            RESTIC="${pkgs.restic}/bin/restic --retry-lock 10m"
            JQ="${pkgs.jq}/bin/jq"

            strip_slash() {
              echo "$1" | sed 's:/*$::'
            }

            is_restic_repo() {
              [ -f "$1/config" ] && [ -d "$1/snapshots" ] && [ -d "$1/keys" ]
            }

            finish() {
              chown -R ${toString syncPath.user}:${toString syncPath.group} "$TARGET"
              chmod -R ${syncPath.mode} "$TARGET"
              echo "Successfully synced ${syncPath.name}"
            }

            echo "Starting sync for ${syncPath.name}"
            echo "Source: $SOURCE"
            echo "Target: $TARGET"

            if ! test -d "${syncPath.nfsMount}"; then
              echo "ERROR: NFS mount directory ${syncPath.nfsMount} does not exist"
              exit 1
            fi

            # Config dir already present locally: leave it alone so containers can start.
            if [ -e "$TARGET" ]; then
              echo "INFO: Target path $TARGET already exists locally, skipping sync"
              exit 0
            fi

            # Nothing on the NAS yet: still create an empty target so containers can start.
            if [ ! -e "$SOURCE" ]; then
              echo "WARNING: Source path $SOURCE does not exist on NAS, creating empty target"
              mkdir -p "$TARGET"
              finish
              exit 0
            fi

            if is_restic_repo "$SOURCE"; then
              if [ ! -f "$PASSWORD_FILE" ]; then
                echo "ERROR: restic repository at $SOURCE but password file $PASSWORD_FILE is missing"
                exit 1
              fi

              export RESTIC_REPOSITORY="$SOURCE"
              export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
              export RESTIC_CACHE_DIR="/var/cache/restic"
              mkdir -p /var/cache/restic

              echo "Detected restic repository, restoring latest snapshot"
              SNAP_JSON=$($RESTIC snapshots --json --latest 1)
              if ! echo "$SNAP_JSON" | $JQ -e 'length > 0' >/dev/null; then
                echo "WARNING: restic repository has no snapshots, creating empty target"
                mkdir -p "$TARGET"
                finish
                exit 0
              fi

              mapfile -t SNAP_PATHS < <(echo "$SNAP_JSON" | $JQ -r 'sort_by(.time) | reverse | .[0].paths[]')
              TARGET_NORM=$(strip_slash "$TARGET")

              if [ "''${#SNAP_PATHS[@]}" -eq 1 ] && [ "$(strip_slash "''${SNAP_PATHS[0]}")" = "$TARGET_NORM" ]; then
                echo "Restoring snapshot in place to $TARGET"
                $RESTIC restore latest --target /
              else
                echo "Restoring snapshot and flattening into $TARGET"
                RESTORE_TMP=$(mktemp -d)
                trap 'rm -rf "$RESTORE_TMP"' EXIT
                $RESTIC restore latest --target "$RESTORE_TMP"
                mkdir -p "$TARGET"
                for p in "''${SNAP_PATHS[@]}"; do
                  if [ -d "$RESTORE_TMP$p" ]; then
                    cp -a "$RESTORE_TMP$p"/. "$TARGET"/
                  else
                    cp -a "$RESTORE_TMP$p" "$TARGET"/
                  fi
                done
              fi

              finish
              exit 0
            fi

            # Legacy rsync tree from before the restic migration.
            echo "Source is a plain directory, rsyncing $SOURCE to $TARGET"
            mkdir -p "$TARGET"
            ${pkgs.rsync}/bin/rsync -av --progress "$SOURCE/" "$TARGET/"
            finish
          '';
        };
      };
    }) config.services.nas-fetch.syncPaths);
  };
}
