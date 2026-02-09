{
  config,
  pkgs,
  ...
}:
let
  constants = import ../constants.nix;
in
{
    sops.secrets.root-password.neededForUsers = true;

    users.users.root = {
        hashedPasswordFile = config.sops.secrets.root-password.path;

        openssh.authorizedKeys.keys = [
            constants.ssh_keys.pongo
        ];
    };
}