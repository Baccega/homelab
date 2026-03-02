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
  hostname_format = "[󱨑 $hostname]($style)";
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
		./hardware-configuration.nix
		./modules/dhcp.nix
		./modules/split-view-dns.nix
		../../modules/common/tailscale.nix
		# ./modules/cloudflared.nix
		./modules/firewall.nix
		./modules/avahi.nix
		../../modules/common/base.nix
		../../modules/common/sops.nix
		../../modules/common/kmscon.nix
		../../users/root.nix
		(import ../../users/sandro.nix { inherit config pkgs hostname_format; })
	];

	networking = {
		hostName = constants.hosts.nemo.hostname;

		# Nemo is the gateway - don't set itself as its own gateway
		# (overrides the default from base.nix, let DHCP on WAN provide the route)
		defaultGateway = lib.mkForce null;

		# WAN interface (external/internet facing)
		interfaces.${constants.hosts.nemo.wanInterface} = {
			useDHCP = true;  # Get IP from upstream router/ISP
		};

		# LAN interface (internal network)
		interfaces.${constants.hosts.nemo.lanInterface} = {
			useDHCP = false;
			ipv4.addresses = [{
				address = constants.hosts.nemo.ip;
				prefixLength = 24;
			}];
		};

		# VLAN sub-interfaces for network segmentation
		vlans = {
			vlan20 = { id = constants.network.vlans.servers.id; interface = constants.hosts.nemo.lanInterface; };
			vlan30 = { id = constants.network.vlans.iot.id;     interface = constants.hosts.nemo.lanInterface; };
			vlan40 = { id = constants.network.vlans.home.id;    interface = constants.hosts.nemo.lanInterface; };
		};

		interfaces.vlan20 = {
			useDHCP = false;
			ipv4.addresses = [{ address = constants.network.vlans.servers.gateway; prefixLength = 24; }];
		};
		interfaces.vlan30 = {
			useDHCP = false;
			ipv4.addresses = [{ address = constants.network.vlans.iot.gateway; prefixLength = 24; }];
		};
		interfaces.vlan40 = {
			useDHCP = false;
			ipv4.addresses = [{ address = constants.network.vlans.home.gateway; prefixLength = 24; }];
		};

		# Disable global DHCP (we configure interfaces explicitly)
		useDHCP = false;

		# Enable NAT for all internal networks
		nat = {
			enable = true;
			externalInterface = constants.hosts.nemo.wanInterface;
			internalInterfaces = [
				constants.hosts.nemo.lanInterface
				"vlan20"
				"vlan30"
				"vlan40"
			];
		};
	};

	# Enable IP forwarding
	boot.kernel.sysctl = {
		"net.ipv4.ip_forward" = 1;
		"net.ipv6.conf.all.forwarding" = 1;
	};

	# Extra Tailscale configuration for Nemo
	services.tailscale = {
		useRoutingFeatures = "server";
		extraSetFlags = [
			"--advertise-routes=${constants.network.vlans.admin.subnet},${constants.network.vlans.servers.subnet},${constants.network.vlans.iot.subnet},${constants.network.vlans.home.subnet}"
		];
	};

	# Home manager
	home-manager.users.sandro.home = {
		username = constants.users.sandro.name;
		homeDirectory = constants.users.sandro.home;
		stateVersion = "25.05";
		file."useful-commands.md".source = ./home/useful-commands.md;
	};
}
