# One-way ROM mirror: Hachiko NFS → local SSD on Bolt.
#
# /mnt/roms-remote  – NFSv4 from Hachiko (read source only)
# /mnt/roms         – local directory on Bolt's disk (what RetroArch uses)
#
# Every 5 minutes (and shortly after boot) rsync copies remote → local.
# Nothing is ever written back to the NAS from this path.
{
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  roms = constants.mountPoints.roms;
  remotePath = "${roms.path}-remote";
  localPath = roms.path;

  remoteAutomountUnit = "mnt-roms\\x2dremote.automount";
in
{
  environment.systemPackages = [ pkgs.rsync ];

  systemd.tmpfiles.rules = [
    "d ${localPath} 0755 root root -"
  ];

  systemd.services.rom-sync = {
    description = "Mirror ROM library from NFS to local disk (one-way)";
    after = [
      "network-online.target"
      remoteAutomountUnit
    ];
    wants = [
      "network-online.target"
      remoteAutomountUnit
    ];
    path = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.rsync
      pkgs.findutils
    ];
    serviceConfig = {
      Type = "oneshot";
      # Long first sync of a big library is fine.
      TimeoutStartSec = "6h";
      ExecStart = pkgs.writeShellScript "rom-sync" ''
        set -euo pipefail

        REMOTE="${remotePath}"
        LOCAL="${localPath}"

        # Trigger automount / ensure NFS is actually mounted.
        if ! ls "$REMOTE" >/dev/null 2>&1; then
          echo "ERROR: cannot access $REMOTE"
          exit 1
        fi
        if ! mountpoint -q "$REMOTE"; then
          echo "ERROR: $REMOTE is not an NFS mount"
          exit 1
        fi

        # Refuse to mirror an empty/broken remote (avoids wiping local with --delete).
        if [ -z "$(find "$REMOTE" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
          echo "ERROR: $REMOTE looks empty; refusing sync"
          exit 1
        fi

        mkdir -p "$LOCAL"
        echo "Syncing $REMOTE/ -> $LOCAL/"
        rsync -a --delete --info=stats2 "$REMOTE/" "$LOCAL/"
        echo "ROM sync finished"
      '';
    };
  };

  systemd.timers.rom-sync = {
    description = "Periodically mirror ROMs from NFS to local disk";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
      Unit = "rom-sync.service";
    };
  };
}
