{
	modulesPath,
	lib,
	pkgs,
	inputs,
	...
}:
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
			address = "192.168.1.60";
			prefixLength = 24;
		}];
	};

	# Home manager
	home-manager.users.sandro.home = { 
		username = "sandro";
		homeDirectory = "/home/sandro";
		file."docker-compose.yml".source = ./home/docker-compose.yml;
		stateVersion = "25.11";
	};

	# Run docker-compose automatically
	systemd.services.my-docker-compose = {
		script = ''
			docker-compose -f /home/sandro/docker-compose.yml
		'';
		wantedBy = ["multi-user.target"];
		after = ["docker.service" "docker.socket"];
	};
}