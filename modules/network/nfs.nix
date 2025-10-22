{ config, pkgs, ... }:
let
  constants = import ../../constants.nix;
in
{
    boot.supportedFilesystems = [ "nfs" ];
    services.rpcbind.enable = true;

    systemd.mounts = [
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4.1";
            };
            what = "${constants.nas.ip}:/volume1/data/movies";
            where = "/mnt/movies";
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4.1";
            };
            what = "${constants.nas.ip}:/volume1/data/tv_shows";
            where = "/mnt/tv_shows";
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4.1";
            };
            what = "${constants.nas.ip}:/volume1/data/downloads";
            where = "/mnt/downloads";
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4.1";
            };
            what = "${constants.nas.ip}:/volume1/photo/Videocassette e VHS";
            where = "/mnt/videocassette";
        }
    ];

    systemd.automounts = [
        {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
                TimeoutIdleSec = "600";
            };
            where = "/mnt/movies";
        }
        {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
                TimeoutIdleSec = "600";
            };
            where = "/mnt/tv_shows";
        }
        {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
                TimeoutIdleSec = "600";
            };
            where = "/mnt/downloads";
        }
        {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
                TimeoutIdleSec = "600";
            };
            where = "/mnt/videocassette";
        }
    ];
}