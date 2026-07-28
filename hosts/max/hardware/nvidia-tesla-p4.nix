# NVIDIA Tesla P4 (Pascal)
{
  imports = [ ../../../modules/common/hardware/nvidia-pascal.nix ];

  # Keep the device initialized between jobs on a headless compute card.
  hardware.nvidia.nvidiaPersistenced = true;
}
