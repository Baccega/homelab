# Sunshine – Moonlight game-stream host inside the bolt VM.
{
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  retroarchIcon = pkgs.fetchurl {
    url = "https://cdn2.steamgriddb.com/grid/e5819b337a27774ad2921bf27a786d20.png";
    hash = "sha256-bE1vFe7hVG3SaK4AwiY9Q+h5h32cX7/OBmAu68jKziA=";
  };
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
    applications = {
      env = {
        PATH = "/run/current-system/sw/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Steam Big Picture";
          detached = [
            "${pkgs.util-linux}/bin/setsid steam steam://open/bigpicture"
          ];
          image-path = "steam.png";
        }
        {
          name = "RetroArch";
          detached = [
            "${pkgs.util-linux}/bin/setsid retroarch"
          ];
          image-path = "${retroarchIcon}";
        }
      ];
    };
  };
}
