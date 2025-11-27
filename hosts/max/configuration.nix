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
		./modules/home-assistant.nix
		./modules/code-server.nix
		./modules/n8n.nix
		./modules/uptime-kuma.nix
		./modules/cloudflared.nix
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

	# Grant users group access to /home/sandro
	systemd.tmpfiles.rules = [
		"d ${constants.users.sandro.home} 0775 ${constants.users.sandro.name} ${toString constants.groups.users} -"
	];

	systemd.services.create-podman-network-max-network-stack = {
		description = "Create podman max-network-stack ipvlan network";
		after = [ "network.target" ];
		wantedBy = [ "multi-user.target" ];
		
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = true;
			ExecStart = pkgs.writeShellScript "create-podman-network" ''
				set -e
				NETWORK_NAME="${constants.network.maxNetworkStack.name}"
				if ${pkgs.podman}/bin/podman network exists "$NETWORK_NAME" 2>/dev/null; then
					echo "Network $NETWORK_NAME already exists"
					exit 0
				fi
				
				# Create the network
				echo "Creating network: $NETWORK_NAME"
				${pkgs.podman}/bin/podman network create \
					--driver ipvlan \
					--opt parent=eno1 \
					--subnet ${constants.network.subnet} \
					--gateway ${constants.network.gateway} \
					--ip-range ${constants.network.maxNetworkStack.ipRange} \
					--route ${constants.network.subnet},${constants.network.gateway} \
					"$NETWORK_NAME"
				
				echo "Network $NETWORK_NAME created successfully"
			'';
		};
	};

	# Enable Podman's built-in auto-update timer
	systemd.timers.podman-auto-update = {
		wantedBy = [ "timers.target" ];
		timerConfig = {
			OnCalendar = "daily";
			RandomizedDelaySec = "1h";
		};
	};
}