# Sunshine – Moonlight game-stream host inside the bolt VM.
{
  pkgs,
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
    # Enable NVENC for the passed-through GTX 1050 Ti.
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
    autoStart = true;
    openFirewall = true;
    # X11 capture; CAP_SYS_ADMIN can break the X11 path.
    capSysAdmin = false;
    settings = {
      sunshine_name = constants.hosts.bolt.hostname;
      virtual_sink = "sunshine-virtual";
      audio_sink = "sunshine-virtual";
      csrf_allowed_origins = "https://${constants.hosts.bolt.ip}";
    };
  };
}
