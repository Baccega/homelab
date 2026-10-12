{ ... }:
let
  constants = import ../../../constants.nix;
in
{
  # Bookshelf is no longer running. Keep restoring and snapshotting its
  # Backups directory so the old library config stays on the NAS.
  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "bookshelf-configs";
        nfsMount = constants.mountPoints.configurations.path;
        source = "bookshelf";
        target = "${constants.users.sandro.home}/bookshelf/Backups/";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "bookshelf-configs";
        source = "${constants.users.sandro.home}/bookshelf/Backups";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "bookshelf";
        appBackups = true;
        schedule = "daily";
      }
    ];
  };
}
