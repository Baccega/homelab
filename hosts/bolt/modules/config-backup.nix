# Backup / restore Sunshine + RetroArch configs via Hachiko configurations share.
{
  ...
}:
let
  constants = import ../../../constants.nix;
  home = constants.users.sandro.home;
  nfsMount = constants.mountPoints.configurations.path;
in
{
  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "sunshine-configs";
        nfsMount = nfsMount;
        source = "bolt/sunshine";
        target = "${home}/.config/sunshine";
        user = constants.users.sandro.uid;
        group = constants.groups.users;
      }
      {
        name = "retroarch-configs";
        nfsMount = nfsMount;
        source = "bolt/retroarch";
        target = "${home}/.config/retroarch";
        user = constants.users.sandro.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "sunshine-configs";
        source = "${home}/.config/sunshine";
        nfsMount = nfsMount;
        destination = "bolt/sunshine";
        schedule = "daily";
      }
      {
        name = "retroarch-configs";
        source = "${home}/.config/retroarch";
        nfsMount = nfsMount;
        destination = "bolt/retroarch";
        exclude = [
          "caches/"
          "temp/"
          "logs/"
        ];
        schedule = "daily";
      }
    ];
  };
}
