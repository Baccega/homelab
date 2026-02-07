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
		../../modules/common/tailscale.nix
		# ./modules/cloudflared.nix
		# ./modules/firewall.nix 
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

		# Disable global DHCP (we configure interfaces explicitly)
		useDHCP = false;

		# Enable IP forwarding for routing
		nat = {
			enable = true;
			externalInterface = constants.hosts.nemo.wanInterface;
			internalInterfaces = [ constants.hosts.nemo.lanInterface ];
		};
	};

	# Enable IP forwarding
	boot.kernel.sysctl = {
		"net.ipv4.ip_forward" = 1;
		"net.ipv6.conf.all.forwarding" = 1;
	};

	# Home manager
	home-manager.users.sandro.home = {
		username = constants.users.sandro.name;
		homeDirectory = constants.users.sandro.home;
		stateVersion = "25.05";
		file."useful-commands.md".source = ./home/useful-commands.md;
	};
}
