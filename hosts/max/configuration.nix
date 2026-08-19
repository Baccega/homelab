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
		./modules/speed-test.nix
		./modules/esphome.nix
		./modules/bookshelf.nix
		./modules/suwayomi.nix
		./modules/komga.nix
		./modules/beszel.nix
		./modules/paperless.nix
		./modules/postgres.nix
		./modules/redis.nix
		./modules/ai-stack.nix
		# ./modules/wolf.nix
		./modules/gaming-vm.nix
		# 1050 Ti is bound to vfio for bolt
		# ./hardware/nvidia-gtx-1050ti.nix
		./hardware/nvidia-tesla-p4.nix
		# ./hardware/intel-a750.nix
		../../modules/common/base.nix
		./modules/max-sops.nix
		../../modules/common/tailscale.nix
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
		useDHCP = false;
		# Bridge so libvirt VMs (bolt) and the host share VLAN 20 L2.
		# eno1 is a bridge port (no IP); Max's address lives on br0.
		bridges.${constants.hosts.max.bridge}.interfaces = [
			constants.hosts.max.lanInterface
		];
		interfaces.${constants.hosts.max.bridge}.ipv4.addresses = [{
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

	systemd.services.create-podman-network-max-network-stack = {
		description = "Create podman max-network-stack ipvlan network";
		after = [
			"network-online.target"
			"sys-subsystem-net-devices-${constants.hosts.max.bridge}.device"
		];
		wants = [ "network-online.target" ];
		wantedBy = [ "multi-user.target" ];

		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = true;
			ExecStart = pkgs.writeShellScript "create-podman-network" ''
				set -e
				NETWORK_NAME="${constants.hosts.max.networkStack.name}"
				PARENT="${constants.hosts.max.bridge}"
				PODMAN="${pkgs.podman}/bin/podman"

				create_network() {
					echo "Creating network: $NETWORK_NAME (ipvlan parent=$PARENT)"
					"$PODMAN" network create \
						--driver ipvlan \
						--opt parent="$PARENT" \
						--subnet ${constants.network.vlans.servers.subnet} \
						--gateway ${constants.network.vlans.servers.gateway} \
						--ip-range ${constants.hosts.max.networkStack.ipRange} \
						--route ${constants.network.vlans.servers.subnet},${constants.network.vlans.servers.gateway} \
						"$NETWORK_NAME"
					echo "Network $NETWORK_NAME created successfully"
				}

				if "$PODMAN" network exists "$NETWORK_NAME" 2>/dev/null; then
					CURRENT_PARENT=$("$PODMAN" network inspect -f '{{index .Options "parent"}}' "$NETWORK_NAME" 2>/dev/null || true)
					if [ "$CURRENT_PARENT" = "$PARENT" ]; then
						echo "Network $NETWORK_NAME already exists (parent=$PARENT)"
						exit 0
					fi
					echo "Migrating $NETWORK_NAME parent '$CURRENT_PARENT' -> '$PARENT'"
					# Network cannot be removed while endpoints are attached.
					for id in $("$PODMAN" ps -q --filter "network=$NETWORK_NAME"); do
						"$PODMAN" stop "$id" || true
					done
					"$PODMAN" network rm "$NETWORK_NAME"
				fi

				create_network
			'';
		};
	};

}