# NFS mount of ROM library from Hachiko (Synology).
{
  ...
}:
let
  constants = import ../../../constants.nix;
  roms = constants.mountPoints.roms;
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
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      where = roms.path;
    }
  ];
}
