# Bolt – gaming NixOS guest on Max (libvirt + GTX 1050 Ti passthrough).
#
# Install once into the qcow2 volume created by hosts/max/modules/gaming-vm.nix,
# then manage with nixinate (flake app) or: nixos-rebuild --flake .#bolt
#
# Bootstrap sketch (on Max, after VT-d + gaming-vm are deployed):
#   1. Attach a NixOS installer ISO / use nixos-anywhere against the domain
#   2. Install flake #bolt onto /dev/vda
#   3. virsh start bolt && ssh sandro@192.168.20.50
# Console password (temporary): bolt / bolt — replace with sops later.
{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}:
let
  constants = import ../../constants.nix;
  hostname_format = "[󰊠 $hostname]($style)";
  bolt = constants.hosts.bolt;
  username = constants.users.sandro.name;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
    ./modules/sunshine.nix
    ../../modules/common/hardware/nvidia-pascal.nix
    ../../modules/common/base.nix
    ../../modules/common/kmscon.nix
    (import ../../modules/common/fish.nix { inherit config pkgs username; })
    (import ../../modules/common/starship.nix {
      inherit config pkgs username hostname_format;
    })
    ../../modules/common/fonts.nix
  ];

  # Guest does not run the Podman service stack from base.nix.
  virtualisation.podman.enable = lib.mkForce false;
  virtualisation.containers.enable = lib.mkForce false;

  users.mutableUsers = true;

  users.users.root = {
    initialPassword = "bolt";
    openssh.authorizedKeys.keys = [ constants.ssh_keys.pongo ];
  };

  users.users.${username} = {
    isNormalUser = true;
    uid = constants.users.sandro.uid;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "input"
      "render"
    ];
    initialPassword = "bolt";
    createHome = true;
    home = constants.users.sandro.home;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [ constants.ssh_keys.pongo ];
  };

  networking = {
    hostName = bolt.hostname;
    # Virtio NIC on pcie-root-port bus 1 → enp1s0; MAC pinned to constants.
    interfaces.enp1s0 = {
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };

  home-manager.users.${username}.home = {
    username = username;
    homeDirectory = constants.users.sandro.home;
    stateVersion = "25.05";
  };

  # Avoid unattended reboots mid-stream.
  system.autoUpgrade.allowReboot = lib.mkForce false;
}
