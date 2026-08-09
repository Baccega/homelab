# Standalone PCSX2 for Bolt (Sunshine), pointed at the local ROM mirror + NAS BIOS.
#
# ROMs:  /mnt/roms/ps2          (mirrored by rom-sync.nix)
# BIOS:  /mnt/roms/BIOSes/pcsx2/bios
# Saves / memcards / settings: ~/.config/PCSX2 (backed up to Hachiko via config-backup.nix)
{
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  username = constants.users.sandro.name;
  home = constants.users.sandro.home;
  roms = constants.mountPoints.roms.path;
  biosDir = "${roms}/BIOSes/pcsx2/bios";
  gamesDir = "${roms}/ps2";
  # European BIOS — matches PAL titles currently in the library.
  biosFile = "ps2-0200e-20040614.bin";

  pcsx2Ini = pkgs.writeText "PCSX2.ini" ''
    [UI]
    SettingsVersion = 1
    StartFullscreen = true
    InhibitScreensaver = true
    ConfirmShutdown = false

    [Folders]
    Bios = ${biosDir}
    Snapshots = snaps
    Savestates = sstates
    MemoryCards = memcards
    Logs = logs
    Cheats = cheats
    Patches = patches
    Cache = cache
    Textures = textures
    InputProfiles = inputprofiles
    Videos = videos

    [Filenames]
    BIOS = ${biosFile}

    [GameList]
    RecursivePaths = ${gamesDir}

    [EmuCore/GS]
    # 12 = Vulkan (Hardware). Native scale — Bolt's Xeon can't afford upscaling.
    Renderer = 12
    upscale_multiplier = 1
    AspectRatio = Auto 4:3/3:2 Standard
    VsyncEnable = 0

    [EmuCore/Speedhacks]
    # MTVU helps on multi-core hosts; EE cycle skip can recover FPS on weak CPUs.
    vuThread = true
    eeCycleRate = 0
    eeCycleSkip = 0
  '';
in
{
  environment.systemPackages = [ pkgs.pcsx2 ];

  systemd.tmpfiles.rules = [
    "d ${home}/.config/PCSX2           0755 ${username} users -"
    "d ${home}/.config/PCSX2/inis      0755 ${username} users -"
    "d ${home}/.config/PCSX2/memcards  0755 ${username} users -"
    "d ${home}/.config/PCSX2/sstates   0755 ${username} users -"
    "d ${home}/.config/PCSX2/snaps     0755 ${username} users -"
    "d ${home}/.config/PCSX2/logs      0755 ${username} users -"
    "d ${home}/.config/PCSX2/cache     0755 ${username} users -"
  ];

  home-manager.users.${username} = {
    home.file.".config/PCSX2/inis/PCSX2.ini" = {
      source = pcsx2Ini;
      force = true;
    };
  };
}
