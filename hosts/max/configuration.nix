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
		./hardware/nvidia-1050ti.nix
		../../modules/common/base.nix
		../../modules/common/sops.nix
		../../modules/common/kmscon.nix
		../../modules/network/nfs.nix
		../../users/root.nix
		(import ../../users/sandro.nix { inherit config pkgs hostname_format; })
		
	];

	networking = {
		hostName = constants.max.hostname; 
		interfaces.eno1.ipv4.addresses = [{
			address = constants.max.ip;
			prefixLength = 24;
		}];

		firewall.allowedTCPPorts = [ 
			6767  # Bazaar
		];
	};

	# Home manager
	home-manager.users.sandro.home = {
		username = "sandro";
		homeDirectory = "/home/sandro";
		file."docker-compose.yml".source = ./home/docker-compose.yml;
		file."docker-constants.env".text = ''
			DNS_PRIMARY=${builtins.elemAt constants.network.dns 0}
			DNS_SECONDARY=${builtins.elemAt constants.network.dns 1}
		'';
		
		stateVersion = "25.05";
	};

	systemd.services.docker-compose = {
		description = "Run docker-compose (root) from Home Manager hook";
		# Collect all services ending with -config.service
		after = [ "docker.service" "network.target" ] ++ 
			(lib.filter (name: lib.hasSuffix "-config.service" name) 
				(builtins.attrNames config.systemd.services));
		requires = [ "docker.service" ];
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = false;
			User = "root";
			WorkingDirectory = "/home/sandro";
		};
		script = ''
			${pkgs.docker-compose}/bin/docker-compose \
			--env-file ${config.sops.secrets.max-docker-env.path} \
			--env-file /home/sandro/docker-constants.env \
			-f /home/sandro/docker-compose.yml \
			up -d --remove-orphans
		'';
	};
}