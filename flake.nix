{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixinate.url = "github:matthewcroughan/nixinate";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixinate,
      disko,
      ...
    }:
    {
      apps = nixinate.nixinate.aarch64-darwin self;
      nixosConfigurations = {
        laika = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/laika/configuration.nix
            {
              _module.args.nixinate = {
                host = "192.168.1.112";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
            }
          ];
        };
      };
    };
}