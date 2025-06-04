{ config, pkgs, username, ... }:
{   
    home-manager.users.${username} = {
        programs.starship.enable = true;
    };

    programs.fish = {
        shellInit = ''
            starship init fish | source
        '';
    };
}