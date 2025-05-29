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