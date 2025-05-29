{
  config,
  pkgs,
  ...
}:
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
            "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHjZD18KxdxjrFiWQm54dP4vDRbZLtMI3C+Pf9LUdHIjjbeAF3AJ3CgQxaA/R1Nao6QmnxrtRp9ljAwrvMhGIK0XgC9rEUcIpNGZH7SB6IYfWreWjITQxyIKgBJuwhR7dTvdaEyINPjLunJtQUJtpCdHio8CAc28aBY6JxUh0dyaUVY0w== MacBook-Pro-Chax"
        ];
    };
}