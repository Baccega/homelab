{
  config,
  pkgs,
  ...
}:
let
  constants = import ../constants.nix;
in
{
    sops.secrets.sandro-password.neededForUsers = true;
    users.mutableUsers = false;

    home-manager.users.sandro = {
        programs.fish.enable = true;
    };

    programs.bash = {
        interactiveShellInit = ''
            if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
            then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
            fi
        '';
    };

    users.users.sandro = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [
            "wheel" "networkmanager" "docker"
        ];
        hashedPasswordFile = config.sops.secrets.sandro-password.path;
        # shell = pkgs.fish;
        createHome = true;
        home = "/home/sandro";

        openssh.authorizedKeys.keys = [
            constants.ssh_keys.macbook_pro_chax
        ];
    };
}