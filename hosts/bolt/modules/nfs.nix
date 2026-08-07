# NFS mounts from Hachiko for the bolt gaming guest.
{
  ...
}:
let
  constants = import ../../../constants.nix;
  roms = constants.mountPoints.roms;
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
      where = roms.path;
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
      where = roms.path;
    }
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      where = configurations.path;
    }
  ];
}
