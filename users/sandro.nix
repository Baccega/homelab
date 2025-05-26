{
  config,
  pkgs,
  ...
}:
{
    sops.secrets.sandro-password.neededForUsers = true;
    users.mutableUsers = false;

    users.users.sandro = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [
            "wheel" "networkmanager"
        ];
        hashedPasswordFile = config.sops.secrets.sandro-password.path;
        # shell = pkgs.fish;
        createHome = true;
        home = "/home/sandro";
    };
}