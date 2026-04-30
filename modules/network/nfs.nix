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
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/configurations";
            where = constants.mountPoints.configurations.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/data/movies";
            where = constants.mountPoints.movies.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/data/tv_shows";
            where = constants.mountPoints.tv_shows.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/data/downloads";
            where = constants.mountPoints.downloads.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/photo/Videocassette e VHS";
            where = constants.mountPoints.videocassette.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/data/books";
            where = constants.mountPoints.books.path;
        }
        {
            type = "nfs";
            mountConfig = {
                Options = "noatime,nfsvers=4";
            };
            what = "${constants.hosts.hachiko.ip}:/volume2/data/manga";
            where = constants.mountPoints.manga.path;
        }
    ];

    systemd.automounts = [
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.configurations.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.movies.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.tv_shows.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.downloads.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.videocassette.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.books.path;
        }
        {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            where = constants.mountPoints.manga.path;
        }
    ];
}