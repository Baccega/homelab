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
}