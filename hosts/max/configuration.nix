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
		./modules/sonarr.nix
		./modules/radarr.nix
		./modules/prowlarr.nix
		./modules/plex.nix
		./hardware/nvidia-1050ti.nix
		../../modules/common/base.nix
		../../modules/common/sops.nix
		../../modules/common/kmscon.nix
		../../modules/network/nfs.nix
		../../modules/common/nas-fetch.nix
		../../modules/common/backup.nix
		../../users/root.nix
		(import ../../users/sandro.nix { inherit config pkgs hostname_format; })
		../../users/alfred.nix
	];

	networking = {
		hostName = constants.hosts.max.hostname; 
		interfaces.eno1.ipv4.addresses = [{
			address = constants.hosts.max.ip;
			prefixLength = 24;
		}];
	};

	# Home manager
	home-manager.users.sandro.home = {
		username = constants.users.sandro.name;
		homeDirectory = constants.users.sandro.home;
		file."useful-commands.md".source = ./home/useful-commands.md;
		stateVersion = "25.05";
	};

	systemd.services.podman-create-network-media-stack = {
		description = "Create podman media-stack network";
		serviceConfig.Type = "oneshot";
		serviceConfig.ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman network exists media-stack || ${pkgs.podman}/bin/podman network create media-stack'";
		wantedBy = [ "multi-user.target" ];
	}; 
}