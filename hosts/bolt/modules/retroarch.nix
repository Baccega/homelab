# RetroArch on the bolt gaming guest (Sunshine / Moonlight).
{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    (retroarch.withCores (
      cores: with cores; [
        beetle-psx-hw # PS1
        pcsx2 # PS2
        fbneo # Neo Geo (and other arcade)
        ppsspp # PSP
      ]
    ))
  ];
}
