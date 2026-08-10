# RetroArch on the bolt gaming guest (Sunshine / Moonlight).
{
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  cores = with pkgs.libretro; [
    beetle-psx-hw # PS1
    fbneo # Neo Geo (and other arcade)
    ppsspp # PSP
  ];
in
{
  environment.systemPackages = [
    (pkgs.retroarch-bare.wrapper {
      inherit cores;
      settings = {
        # Local SSD mirror of the NAS ROM library (rom-sync.nix).
        rgui_browser_directory = constants.mountPoints.roms.path;
        content_directory = constants.mountPoints.roms.path;
      };
    })
  ];
}
