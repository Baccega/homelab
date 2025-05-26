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
		../../users/sandro.nix
	];

	networking = {
		hostName = "laika"; 
		interfaces.wlp2s0.ipv4.addresses = [{
			address = "192.168.1.60";
			prefixLength = 24;
		}];
	};

	users.users.root.initialPassword = "1234";
	users.users.root.openssh.authorizedKeys.keys = [
		"ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHjZD18KxdxjrFiWQm54dP4vDRbZLtMI3C+Pf9LUdHIjjbeAF3AJ3CgQxaA/R1Nao6QmnxrtRp9ljAwrvMhGIK0XgC9rEUcIpNGZH7SB6IYfWreWjITQxyIKgBJuwhR7dTvdaEyINPjLunJtQUJtpCdHio8CAc28aBY6JxUh0dyaUVY0w== MacBook-Pro-Chax"
	];
}