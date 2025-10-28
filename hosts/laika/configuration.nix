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
			address = constants.hosts.laika.ip;
			prefixLength = 24;
		}];

		firewall.allowedTCPPorts = [ 
			6767  # Bazaar
			8123  # Home assistant
		];
	};

	# Home manager
	home-manager.users.sandro.home = { 
		username = constants.users.sandro.name;
		homeDirectory = constants.users.sandro.home;
		file."docker-compose.yml".source = ./home/docker-compose.yml;
		stateVersion = "25.05";
	};

	systemd.services.docker-compose = {
		description = "Run docker-compose (root) from Home Manager hook";
		after = [ "docker.service" "network.target" ];
		requires = [ "docker.service" ];
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = false;
			User = "root";
			WorkingDirectory = constants.users.sandro.home;
		};
		script = ''
			${pkgs.docker-compose}/bin/docker-compose \
			--env-file ${config.sops.secrets.laika-docker-env.path} \
			-f ${constants.users.sandro.home}/docker-compose.yml \
			up -d --remove-orphans
		'';
	};
}