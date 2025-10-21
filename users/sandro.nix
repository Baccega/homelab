{
  config,
  pkgs,
  hostname_format,
  ...
}:
let
  constants = import ../constants.nix;
  username = "sandro";
in
{
    imports = [
        (import ../modules/common/fish.nix { inherit config pkgs username; })
        (import ../modules/common/starship.nix { inherit config pkgs username hostname_format; })
        (import ../modules/common/fonts.nix)
    ];

    sops.secrets.sandro-password.neededForUsers = true;
    users.mutableUsers = false;

    users.users.sandro = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [
            "wheel" "networkmanager" "podman"
        ];
        hashedPasswordFile = config.sops.secrets.sandro-password.path;
        createHome = true;
        home = "/home/sandro";

        openssh.authorizedKeys.keys = [
            constants.ssh_keys.macbook_pro_chax
        ];
    };
}