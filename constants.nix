{
    network = {
        gateway = "192.168.1.1";
        dns = [ "1.1.1.1" "8.8.8.8" ];
        forwardProxy = {
            ip = "192.168.1.55";
            port = 1080;
        };
    };
    mountPoints = {
        configurations = {
            path = "/mnt/configurations";
            name = "configurations";
        };
        movies = {
            path = "/mnt/movies";
            name = "movies";
        };
        tv_shows = {
            path = "/mnt/tv_shows";
            name = "tv_shows";
        };
        downloads = {
            path = "/mnt/downloads";
            name = "downloads";
        };
        videocassette = {
            path = "/mnt/videocassette";
            name = "videocassette";
        };
    };
    hosts = {
        laika = {
            hostname = "laika";
            ip = "192.168.1.60";
        };
        nas = {
            ip = "192.168.1.52";
        };
        zero = {
            hostname = "zero";
        };
        max = {
            hostname = "max";
            ip = "192.168.1.55";
        };
    };
    ssh_keys = {
        macbook_pro_chax = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHjZD18KxdxjrFiWQm54dP4vDRbZLtMI3C+Pf9LUdHIjjbeAF3AJ3CgQxaA/R1Nao6QmnxrtRp9ljAwrvMhGIK0XgC9rEUcIpNGZH7SB6IYfWreWjITQxyIKgBJuwhR7dTvdaEyINPjLunJtQUJtpCdHio8CAc28aBY6JxUh0dyaUVY0w== MacBook-Pro-Chax";
    };
    users = {
        sandro = 1000;
        alfred = 1050;
    };
    groups = {
        users = 100;
    };
    services = {
        qbittorrent = {
            port = 8080;
            torrentPort = 6881;
        };
        sabnzbd = {
            port = 8081;
        };
        sonarr = {
            port = 8989;
        };
        radarr = {
            port = 7878;
        };
        prowlarr = {
            port = 9696;
        };
    };
}