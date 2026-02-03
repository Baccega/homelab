{
    network = {
        gateway = "192.168.1.1";
        subnet = "192.168.1.0/24";
        dns = [ "1.1.1.1" "8.8.8.8" ];
        dhcp = {
            rangeStart = "192.168.1.100";
            rangeEnd = "192.168.1.199";
        };
        maxNetworkStack = {
            name = "max-network-stack";
            ipRange = "192.168.1.200/28";
        };
        switch1 = {
            ip = "192.168.1.2";
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
        zero = {
            hostname = "zero";
        };
        laika = {
            hostname = "laika";
            ip = "192.168.1.60";
        };
        hachiko = {
            hostname = "hachiko";
            ip = "192.168.1.56";
        };
        max = {
            hostname = "max";
            ip = "192.168.1.55";
        };
        nemo = {
            hostname = "nemo";
            ip = "192.168.1.1";
            wanInterface = "enp1s0";
            lanInterface = "enp2s0";
        };
        balto = {
            hostname = "balto";
            ip = "192.168.1.52";
        };
    };
    ssh_keys = {
        macbook_pro_chax = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHjZD18KxdxjrFiWQm54dP4vDRbZLtMI3C+Pf9LUdHIjjbeAF3AJ3CgQxaA/R1Nao6QmnxrtRp9ljAwrvMhGIK0XgC9rEUcIpNGZH7SB6IYfWreWjITQxyIKgBJuwhR7dTvdaEyINPjLunJtQUJtpCdHio8CAc28aBY6JxUh0dyaUVY0w== MacBook-Pro-Chax";
    };
    users = {
        sandro = {
            uid = 1000;
            name = "sandro";
            home = "/home/sandro";
        };
        alfred = {
            uid = 1050;
            name = "alfred";
        };
    };
    groups = {
        users = 100;
    };
    services = {
        forwardProxy = {
            ip = "192.168.1.200";
            port = 1080;
        };
        plex = {
            ip = "192.168.1.201";
        };
        qbittorrent = {
            port = 8080;
            torrentPort = 6881;
            ip = "192.168.1.202";
        };
        sabnzbd = {
            port = 8080;
            ip = "192.168.1.203";
        };
        sonarr = {
            port = 8989;
            ip = "192.168.1.204";
        };
        radarr = {
            port = 7878;
            ip = "192.168.1.205";
        };
        prowlarr = {
            port = 9696;
            ip = "192.168.1.206";
        };
        homeAssistant = {
            port = 8123;
            ip = "192.168.1.207";
        };
        codeServer = {
            port = 8443;
            ip = "192.168.1.208";
        };
        n8n = {
            port = 5678;
            ip = "192.168.1.209";
        };
        cloudflared = {
            ip = "192.168.1.210";
        };
        uptimeKuma = {
            port = 3001;
            ip = "192.168.1.211";
        };
        esphome = {
            port = 6052;
            ip = "192.168.1.212";
        };
    };
}