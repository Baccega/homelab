# Bolt – gaming NixOS guest on Max (libvirt + GTX 1050 Ti passthrough).
#
# Install once into the qcow2 volume created by hosts/max/modules/gaming-vm.nix,
# then manage with nixinate (flake app) or: nixos-rebuild --flake .#bolt
#
# Bootstrap sketch (on Max, after VT-d + gaming-vm are deployed):
#   1. Attach a NixOS installer ISO / use nixos-anywhere against the domain
#   2. Install flake #bolt onto /dev/vda
#   3. virsh start bolt && ssh sandro@192.168.20.50
{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}:
let
  constants = import ../../constants.nix;
  hostname_format = "[ $hostname]($style)";
  bolt = constants.hosts.bolt;
  username = constants.users.sandro.name;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
    ./modules/sunshine.nix
    ./modules/steam.nix
    ./modules/retroarch.nix
    ./modules/pcsx2.nix
    ./modules/nfs.nix
    ./modules/rom-sync.nix
    ./modules/config-backup.nix
    ./modules/bolt-sops.nix
    ../../modules/common/hardware/nvidia-pascal.nix
    ../../modules/common/base.nix
    ../../modules/common/nas-fetch.nix
    ../../modules/common/backup.nix
    ../../modules/common/tailscale.nix
    ../../modules/common/kmscon.nix
    ../../users/root.nix
    (import ../../users/sandro.nix { inherit config pkgs hostname_format; })
  ];

  # Guest does not run the Podman service stack from base.nix.
  virtualisation.podman.enable = lib.mkForce false;
  virtualisation.containers.enable = lib.mkForce false;

  # virsh console → libvirt isa-serial → ttyS0
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    terminal_input serial console
    terminal_output serial console
  '';
  systemd.services."serial-getty@ttyS0".enable = true;

  users.users.${username}.extraGroups = lib.mkForce [
    "wheel"
    "video"
    "audio"
    "input"
    "render"
  ];

  networking = {
    hostName = bolt.hostname;
    useDHCP = false;
    interfaces.enp2s0 = {
      useDHCP = false;
      macAddress = bolt.mac;
      ipv4.addresses = [
        {
          address = bolt.ip;
          prefixLength = 24;
        }
      ];
    };
    firewall.allowedTCPPorts = [
      22
      constants.services.sunshine.httpsPort
      constants.services.sunshine.httpPort
      constants.services.sunshine.webUiPort
      constants.services.sunshine.rtspPort
    ];
    firewall.allowedUDPPorts = [
      constants.services.sunshine.videoPort
      constants.services.sunshine.controlPort
      constants.services.sunshine.audioPort
      constants.services.sunshine.micPort
      constants.services.sunshine.rtspPort
    ];
  };

  services.qemuGuest.enable = true;

  home-manager.users.${username}.home = {
    username = username;
    homeDirectory = constants.users.sandro.home;
    stateVersion = "25.05";
  };

  # Avoid unattended reboots mid-stream.
  system.autoUpgrade.allowReboot = lib.mkForce false;
}
