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
  pcsx2Icon = pkgs.fetchurl {
    url = "https://cdn2.steamgriddb.com/grid/7d1c670a8c324c56a1c757c3a3a7d33e.png";
    hash = "sha256-9CjvZlJz+flx7vjuYA77I7BC87YX1IfQygwL4o2UQn8=";
  };

  # The nixpkgs RetroArch wrapper's process name is ".retroarch-wrapped"
  # (comm shows as "...retroarch-wr"), NOT "retroarch". `pkill -x retroarch`
  # never matched, so every Moonlight launch stacked another frozen window.
  killRetroarch = pkgs.writeShellScript "kill-retroarch" ''
    set +e
    ${pkgs.procps}/bin/pkill -f '/\.retroarch-wrapped' >/dev/null 2>&1
    ${pkgs.coreutils}/bin/sleep 0.4
    ${pkgs.procps}/bin/pkill -9 -f '/\.retroarch-wrapped' >/dev/null 2>&1
    ${pkgs.procps}/bin/pkill -f 'xdg-screensaver suspend' >/dev/null 2>&1
    exit 0
  '';

  launchRetroarch = pkgs.writeShellScript "sunshine-retroarch" ''
    set -euo pipefail
    ${killRetroarch}
    ${pkgs.coreutils}/bin/sleep 0.2
    exec retroarch "$@"
  '';

  killPcsx2 = pkgs.writeShellScript "kill-pcsx2" ''
    set +e
    ${pkgs.procps}/bin/pkill -f 'pcsx2-qt|/bin/pcsx2' >/dev/null 2>&1
    ${pkgs.coreutils}/bin/sleep 0.4
    ${pkgs.procps}/bin/pkill -9 -f 'pcsx2-qt|/bin/pcsx2' >/dev/null 2>&1
    exit 0
  '';

  launchPcsx2 = pkgs.writeShellScript "sunshine-pcsx2" ''
    set -euo pipefail
    ${killPcsx2}
    ${pkgs.coreutils}/bin/sleep 0.2
    # Fullscreen Qt UI over the Sunshine virtual display; game list from /mnt/roms/ps2.
    exec ${pkgs.pcsx2}/bin/pcsx2-qt -fullscreen "$@"
  '';
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
          # Managed command (not detached): Sunshine tracks the process and
          # kills it when you quit the Moonlight app.
          # NOTE: Close Content / Restart with the PCSX2 *libretro core* often
          # freezes (upstream core bug). Prefer Quit + relaunch, or use PCSX2.
          cmd = "${launchRetroarch}";
          "auto-detach" = "false";
          "wait-all" = "true";
          "prep-cmd" = [
            {
              do = "${killRetroarch}";
              undo = "${killRetroarch}";
            }
          ];
          image-path = "${retroarchIcon}";
        }
        {
          # Prefer this for PS2: Close/Restart work; libretro PCSX2 often freezes.
          name = "PCSX2";
          cmd = "${launchPcsx2}";
          "auto-detach" = "false";
          "wait-all" = "true";
          "prep-cmd" = [
            {
              do = "${killPcsx2}";
              undo = "${killPcsx2}";
            }
          ];
          image-path = "${pcsx2Icon}";
        }
      ];
    };
  };
}
