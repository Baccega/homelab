# Shared NVIDIA Pascal configuration.
# Source: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/nvidia/pascal/default.nix
{ config, lib, ... }:
{
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

  # The open source driver does not support Pascal GPUs.
  # R580 is the last driver branch that supports Maxwell/Pascal/Volta.
  hardware.nvidia.open = false;
  hardware.nvidia.package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;

  # Required for nvidia-drm modeset=Y (Wolf / Wayland / EGL on /dev/dri).
  hardware.nvidia.modesetting.enable = true;

  hardware.nvidia-container-toolkit.enable = true;
}
