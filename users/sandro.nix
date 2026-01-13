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
        uid = constants.users.sandro.uid;
        extraGroups = [
            "wheel" "networkmanager" "podman"
        ];
        hashedPasswordFile = config.sops.secrets.sandro-password.path;
        createHome = true;
        home = constants.users.sandro.home;
        shell = pkgs.fish;

        openssh.authorizedKeys.keys = [
            constants.ssh_keys.macbook_pro_chax
        ];
    };
}