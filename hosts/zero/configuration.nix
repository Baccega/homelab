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
  hostname_format = "[󰊠 $hostname]($style)";
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
		../../modules/common/base.nix
	];

	networking = {
		hostName = "zero"; 
		useDHCP = lib.mkDefault true;
	};

	users.users.root.openssh.authorizedKeys.keys = [
		constants.ssh_keys.pongo
	];

  	users.users.root.initialPassword = "1234";

	users.users.sandro = {
		isNormalUser = true;
		group = "users";
		extraGroups = [ "wheel" ];
		initialPassword = "1234";
		openssh.authorizedKeys.keys = [
			constants.ssh_keys.pongo
		];
	};

	users.groups.sandro = {};
}