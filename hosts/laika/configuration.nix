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
  hostname_format = "[ $hostname]($style)";
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
		./hardware-configuration.nix
		../../modules/common/base.nix
		../../modules/common/sops.nix
		../../modules/common/kmscon.nix
		../../modules/network/home-wifi.nix
		../../modules/network/nfs.nix
		../../modules/services/home-assistant.nix
		../../users/root.nix
		(import ../../users/sandro.nix { inherit config pkgs hostname_format; })
		
	];

	networking = {
		hostName = "laika"; 
		interfaces.wlp2s0.ipv4.addresses = [{
			address = constants.laika.ip;
			prefixLength = 24;
		}];

		firewall.allowedTCPPorts = [ 
			6767  # Bazaar
			8123  # Home assistant
		];
	};

	# Home manager
	home-manager.users.sandro = { pkgs, lib, osConfig, ... }: { 
		home = {
			username = "sandro";
			homeDirectory = "/home/sandro";
			file."docker-compose.yml".source = ./home/docker-compose.yml;
			stateVersion = "25.05";

			# Restart docker-compose after home manager swapped the files
			activation.restartDockerCompose = lib.hm.dag.entryAfter ["writeBoundary"] ''
				echo "🔄 Restarting docker-compose service after Home Manager activation..."
				/run/current-system/sw/bin/systemctl restart docker-compose.service
			'';
		};
	};

	systemd.services.docker-compose = {
		description = "Run docker-compose (root) from Home Manager hook";
		after = [ "docker.service" "network.target" ];
		requires = [ "docker.service" ];
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = false;
			User = "root";
			WorkingDirectory = "/home/sandro";
		};
		script = ''
			${pkgs.docker-compose}/bin/docker-compose \
			--env-file ${config.sops.secrets.laika-docker-env.path} \
			-f /home/sandro/docker-compose.yml \
			up -d --remove-orphans
		'';
	};
}