# Sunshine – Moonlight game-stream host inside the bolt VM.
{
  ...
}:
let
  constants = import ../../../constants.nix;
in
{
  imports = [
    ./virtual-display.nix
    ./virtual-audio.nix
  ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    # X11 capture; CAP_SYS_ADMIN can break the X11 path.
    capSysAdmin = false;
    settings = {
      sunshine_name = constants.hosts.bolt.hostname;
      virtual_sink = "sunshine-virtual";
      audio_sink = "sunshine-virtual";
    };
  };
}
