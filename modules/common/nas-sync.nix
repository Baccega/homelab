{ config, pkgs, lib, ... }:
let
  constants = import ../../constants.nix;
in
{
  options.services.nas-sync = {
    enable = lib.mkEnableOption "NAS sync service";
    
    syncPaths = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Unique name for this sync operation";
          };
          source = lib.mkOption {
            type = lib.types.str;
            description = "Source path on NAS (relative to mounted NFS share)";
            example = "data/movies";
          };
          target = lib.mkOption {
            type = lib.types.str;
            description = "Target local path";
            example = "/var/lib/movies";
          };
          nfsMount = lib.mkOption {
            type = lib.types.str;
            description = "NFS mount point to use as base";
            default = "/mnt/movies";
            example = "/mnt/movies";
          };
          user = lib.mkOption {
            type = lib.types.int;
            description = "User to own the synced files";
            default = 0;
          };
          group = lib.mkOption {
            type = lib.types.int;
            description = "Group to own the synced files";
            default = 0;
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

  config = lib.mkIf config.services.nas-sync.enable {
    # Ensure rsync is available
    environment.systemPackages = with pkgs; [ rsync ];

    # Create systemd services for each sync path
    systemd.services = lib.listToAttrs (map (syncPath: {
      name = "nas-sync-${syncPath.name}";
      value = {
        description = "Sync ${syncPath.name} from NAS";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" syncPath.nfsMount}.mount" ];
        requires = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" syncPath.nfsMount}.mount" ];
        
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = pkgs.writeShellScript "nas-sync-${syncPath.name}.sh" ''
            set -euo pipefail
            
            # Source and target paths
            SOURCE="${syncPath.nfsMount}/${syncPath.source}"
            TARGET="${syncPath.target}"
            
            echo "Starting sync for ${syncPath.name}"
            echo "Source: $SOURCE"
            echo "Target: $TARGET"
            
            # Check if NFS mount is available and accessible
            if ! test -d "${syncPath.nfsMount}"; then
              echo "ERROR: NFS mount directory ${syncPath.nfsMount} does not exist"
              exit 1
            fi
            
            
            # Check if source exists on NAS
            if [ ! -e "$SOURCE" ]; then
              echo "WARNING: Source path $SOURCE does not exist on NAS, skipping sync"
              exit 0
            fi
            
            # Check if target already exists locally
            if [ -e "$TARGET" ]; then
              echo "INFO: Target path $TARGET already exists locally, skipping sync"
              exit 0
            fi
            
            # Create target directory if it doesn't exist
            mkdir -p "$(dirname "$TARGET")"
            
            # Sync from NAS to local
            echo "Syncing $SOURCE to $TARGET"
            ${pkgs.rsync}/bin/rsync -av --progress "$SOURCE/" "$TARGET/"
            
            # Set ownership and permissions
            chown -R ${toString syncPath.user}:${toString syncPath.group} "$TARGET"
            chmod -R ${syncPath.mode} "$TARGET"
            
            echo "Successfully synced ${syncPath.name}"
          '';
        };
      };
    }) config.services.nas-sync.syncPaths);
  };
}
