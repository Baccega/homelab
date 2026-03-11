# Sunshine – open-source game streaming (Moonlight-compatible)
# Uses NVENC via the 1050 Ti for hardware encoding.
# Avahi publishing lets the mDNS reflector on nemo advertise
# the service to clients on the home VLAN.
{ pkgs, ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
  };

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
  };
}
