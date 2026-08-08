# NFS mounts from Hachiko for the bolt gaming guest.
#
# ROM library is mounted read-only-as-source at /mnt/roms-remote and mirrored
# every 5 minutes onto the local /mnt/roms directory (see rom-sync.nix).
# Configurations stay on NFS directly (saves/configs sync is handled elsewhere).
{
  ...
}:
let
  constants = import ../../../constants.nix;
  roms = constants.mountPoints.roms;
  romsRemote = "${roms.path}-remote";
  configurations = constants.mountPoints.configurations;
in
{
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime,nfsvers=4";
      };
      what = "${constants.hosts.hachiko.ip}:/volume2/data/roms";
      where = romsRemote;
    }
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime,nfsvers=4";
      };
      what = "${constants.hosts.hachiko.ip}:/volume2/configurations";
      where = configurations.path;
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      where = romsRemote;
    }
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      where = configurations.path;
    }
  ];
}
