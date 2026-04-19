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
      darwinPkgs = import nixpkgs { system = "aarch64-darwin"; };
      switch1 = import ./hosts/switch1 { pkgs = darwinPkgs; inherit constants; };
    in
    {
      apps = nixpkgs.lib.recursiveUpdate (nixinate.nixinate.aarch64-darwin self) {
        aarch64-darwin = {
          switch1-export = {
            type = "app";
            program = "${switch1.export}/bin/switch1-export";
          };
          switch1-deploy = {
            type = "app";
            program = "${switch1.deploy}/bin/switch1-deploy";
          };
        };
      };
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
                sshUser = constants.users.sandro.name;
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
                host = constants.hosts.max.tailscaleIp;
                sshUser = constants.users.sandro.name;
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
        nemo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            ./hosts/nemo/configuration.nix
            {
              _module.args.nixinate = {
                host = constants.hosts.nemo.tailscaleIp;
                sshUser = constants.users.sandro.name;
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