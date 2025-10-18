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
	};

	users.users.root.openssh.authorizedKeys.keys = [
		constants.ssh_keys.macbook_pro_chax
	];

  	users.users.root.initialPassword = "1234";
}