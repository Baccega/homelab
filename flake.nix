{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixinate.url = "github:matthewcroughan/nixinate";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixinate,
      disko,
      sops-nix,
      ...
    }:
    {
      apps = nixinate.nixinate.aarch64-darwin self;
      nixosConfigurations = {
        laika = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/laika/configuration.nix
            {
              _module.args.nixinate = {
                host = "192.168.1.60";
                sshUser = "sandro";
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