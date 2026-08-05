# Virtual display for headless game streaming (Xorg + NVIDIA ConnectedMonitor).
# Still needed inside the VM: GPU passthrough alone does not create a usable
# capture target if nothing is "connected" to the 1050 Ti.
{
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
in
{
  services.xserver = {
    enable = true;

    # NVIDIA: pretend HDMI-0 is connected and allow non-EDID modes.
    deviceSection = ''
      Option "AllowEmptyInitialConfiguration" "true"
      Option "ConnectedMonitor" "HDMI-0"
      Option "MetaModes" "1920x1080"
      Option "ModeValidation" "NoDFPNativeResolutionCheck,NoVirtualSizeCheck,NoMaxPClkCheck,NoHorizSyncCheck,NoVertRefreshCheck,NoWidthAlignmentCheck"
    '';

    monitorSection = ''
      Option "Enable" "true"
    '';

    screenSection = ''
      DefaultDepth 24
      Option "TwinView" "1"
      SubSection "Display"
        Depth 24
        Modes "1920x1080"
      EndSubSection
    '';

    windowManager.openbox.enable = true;
  };

  # GDM is Wayland-only on current NixOS; Sunshine uses the X11 capture path.
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager = {
    defaultSession = "none+openbox";
    autoLogin = {
      enable = true;
      user = constants.users.sandro.name;
    };
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.systemPackages = with pkgs; [
    xorg.xrandr
    openbox
  ];

  users.users.${constants.users.sandro.name}.extraGroups = [
    "video"
    "input"
    "render"
  ];
}
