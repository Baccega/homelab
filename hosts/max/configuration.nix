{
	modulesPath,
	lib,
	pkgs,
	inputs,
	config,
	...
}:
let
  constants = import ../../constants.nix;
  hostname_format = "[󰩃 $hostname]($style)";
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
		./hardware-configuration.nix
		./modules/qbittorrent.nix
		./modules/sabnzbd.nix
		./modules/forward-proxy.nix
		./hardware/nvidia-1050ti.nix
		../../modules/common/base.nix
		../../modules/common/sops.nix
		../../modules/common/kmscon.nix
		../../modules/network/nfs.nix
		../../users/root.nix
		(import ../../users/sandro.nix { inherit config pkgs hostname_format; })
		../../users/alfred.nix
	];

	networking = {
		hostName = constants.max.hostname; 
		interfaces.eno1.ipv4.addresses = [{
			address = constants.max.ip;
			prefixLength = 24;
		}];
	};

	# Home manager
	home-manager.users.sandro.home = {
		username = "sandro";
		homeDirectory = "/home/sandro";
		file."useful-commands.md".source = ./home/useful-commands.md;
		stateVersion = "25.05";
	};
}