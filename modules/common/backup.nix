{ config, pkgs, lib, ... }:
let
  constants = import ../../constants.nix;
in
{
  options.backup = {
    enable = lib.mkEnableOption "Enable backup service";
    
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
            description = "Destination path on NAS (relative to mounted NFS share)";
            example = "app";
          };
          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of patterns to exclude from backup";
            example = [ "cache" "*.tmp" ".git" ];
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
          rsyncOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "-av" "--delete" "--progress" "--delete-excluded" ];
            description = "Rsync options";
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

  config = lib.mkIf config.backup.enable {
    # Ensure rsync is available
    environment.systemPackages = with pkgs; [ rsync ];
    
    # Create systemd services and timers for each backup job
    systemd.services = lib.listToAttrs (map (jobConfig: {
      name = "backup-${jobConfig.name}";
      value = {
        description = "Backup job: ${jobConfig.name}";
        
        # Service dependencies
        after = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" jobConfig.nfsMount}.mount" ];
        wants = [ "network.target" "mnt-${lib.strings.removePrefix "/mnt/" jobConfig.nfsMount}.mount" ];
        
        serviceConfig = {
          Type = "oneshot";
          User = toString jobConfig.user;
          Group = toString jobConfig.group;
          ExecStart = let
              excludePatterns = [ ".bash_history" ] ++ jobConfig.exclude;
              excludeFileContent = lib.concatStringsSep "\n" excludePatterns;
            in pkgs.writeShellScript "backup-${jobConfig.name}.sh" ''
            set -euo pipefail
            
            # Log function
            log() {
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
            }
            
            log "Starting backup job: ${jobConfig.name}"
            
            # Check if source exists
            if [ ! -e "${jobConfig.source}" ]; then
              log "ERROR: Source path '${jobConfig.source}' does not exist"
              exit 1
            fi
            
            # Check if NFS mount is available and accessible
            if ! test -d "${jobConfig.nfsMount}"; then
              log "ERROR: NFS mount directory ${jobConfig.nfsMount} does not exist"
              exit 1
            fi
            
            # Create destination directory if it doesn't exist
            FULL_DESTINATION="${jobConfig.nfsMount}/${jobConfig.destination}"
            mkdir -p "$FULL_DESTINATION"
            
            # Run pre-backup script if defined
            ${lib.optionalString (jobConfig.preBackupScript != null) ''
              log "Running pre-backup script"
              ${jobConfig.preBackupScript}
            ''}
            
            # Build rsync command
            RSYNC_CMD="${pkgs.rsync}/bin/rsync"
            RSYNC_ARGS="${lib.concatStringsSep " " jobConfig.rsyncOptions}"
            
            # Create exclude file
            EXCLUDE_FILE=$(mktemp)
            cat > "$EXCLUDE_FILE" <<EOF
            ${excludeFileContent}
            EOF

            # Execute backup
            log "Executing: $RSYNC_CMD $RSYNC_ARGS --exclude-from=$EXCLUDE_FILE '${jobConfig.source}/' '$FULL_DESTINATION/'"
            
            if $RSYNC_CMD $RSYNC_ARGS --exclude-from=$EXCLUDE_FILE "${jobConfig.source}/" "$FULL_DESTINATION/"; then
              log "Backup completed successfully"
              
              # Remove exclude file
              rm -f "$EXCLUDE_FILE"

              # Run post-backup script if defined
              ${lib.optionalString (jobConfig.postBackupScript != null) ''
                log "Running post-backup script"
                ${jobConfig.postBackupScript}
              ''}
              
              log "Backup job finished successfully"
            else
              log "ERROR: Backup failed with exit code $?"

              # Remove exclude file
              rm -f "$EXCLUDE_FILE"

              exit 1
            fi
          '';
        };
      };
    }) config.backup.jobs);
    
    # Create systemd timers for each backup job
    systemd.timers = lib.listToAttrs (map (jobConfig: {
      name = "backup-${jobConfig.name}";
      value = {
        description = "Timer for backup job: ${jobConfig.name}";
        wantedBy = [ "timers.target" ];
        
        timerConfig = 
          if jobConfig.schedule == "daily" then {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "3h";
          } else if jobConfig.schedule == "weekly" then {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "5h";
          } else {
            OnCalendar = jobConfig.schedule;
            Persistent = true;
            RandomizedDelaySec = "30m";
          };
      };
    }) config.backup.jobs);
    
    # Create tmpfiles rules to ensure proper permissions for backup access
    systemd.tmpfiles.rules = lib.concatLists (map (jobConfig: 
      let
        homeDir = if lib.hasPrefix "/home/" jobConfig.source then
          lib.head (lib.splitString "/" (lib.removePrefix "/home/" jobConfig.source))
        else null;
      in
      if homeDir != null then [
        "d /home/${homeDir} 0755 ${homeDir} ${toString jobConfig.group} -"
      ] else []
    ) config.backup.jobs);
  };
}
