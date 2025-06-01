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
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
		./hardware-configuration.nix
		../../modules/base.nix
		../../modules/home-wifi.nix
		../../modules/sops.nix
		../../modules/nfs.nix
		../../users/root.nix
		../../users/sandro.nix
	];

	networking = {
		hostName = "laika"; 
		interfaces.wlp2s0.ipv4.addresses = [{
			address = constants.laika.ip;
			prefixLength = 24;
		}];
	};

	# Home manager
	home-manager.users.sandro.home = { 
		username = "sandro";
		homeDirectory = "/home/sandro";
		file."docker-compose.yml".source = ./home/docker-compose.yml;
		stateVersion = "25.05";
	};

	# Run docker-compose
	systemd.services.docker-compose = {
		description = "Start docker compose services";
		after = [ "docker.service" "network.target" ];
		requires = [ "docker.service" ];
		wantedBy = [ "multi-user.target" ];
		path = [ pkgs.docker pkgs.docker-compose ];

		script = ''
			${pkgs.docker-compose}/bin/docker-compose \
			--env-file ${config.sops.secrets.laika-docker-env.path} \
			up -d --remove-orphans
		'';
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = true;
			User = "root";
			WorkingDirectory = "/home/sandro";
		};
	};
	systemd.paths.docker-compose-watcher = {
		wantedBy = [ "multi-user.target" ];
		pathConfig = {
			PathModified = [
				"/home/sandro/docker-compose.yml" 
				config.sops.secrets.laika-docker-env.path
			];
			Unit = "docker-compose.service";
		};
	};
}