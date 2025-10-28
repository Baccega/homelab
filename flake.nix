{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixinate.url = "github:matthewcroughan/nixinate";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixinate,
      disko,
      sops-nix,
      home-manager,
      ...
    }:
    let
      constants = import ./constants.nix;
    in
    {
      apps = nixinate.nixinate.aarch64-darwin self;
      nixosConfigurations = {
        laika = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            ./hosts/laika/configuration.nix
            {
              _module.args.nixinate = {
                host = constants.hosts.laika.ip;
                sshUser = "sandro";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
            }
          ];
        };
        max = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            ./hosts/max/configuration.nix
            {
              _module.args.nixinate = {
                host = constants.hosts.max.ip;
                sshUser = "sandro";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
            }
          ];
        };
        zero = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./hosts/zero/configuration.nix
          ];
        };
      };
    };
}