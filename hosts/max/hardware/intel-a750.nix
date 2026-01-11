{ pkgs, ... }:
{
  # Enable Mesa + DRM (no GUI needed)
  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver   # VA-API (iHD) → REQUIRED for Plex
      vpl-gpu-rt           # oneVPL / Quick Sync (recommended)
    ];
  };

  # Force the modern Intel VA-API driver
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Needed for Intel GPU firmware
  hardware.enableRedistributableFirmware = true;

  # Recommended for Arc GPUs (media + stability)
  boot.kernelParams = [ "i915.enable_guc=3" ];
}
