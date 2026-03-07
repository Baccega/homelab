{
    network = {
        dns = [ "1.1.1.1" "8.8.8.8" ];
        vlans = {
            admin = {
                id = 1;
                subnet = "192.168.1.0/24";
                gateway = "192.168.1.1";
                dhcpRange = { start = "192.168.1.100"; end = "192.168.1.191"; };
            };
            servers = {
                id = 20;
                subnet = "192.168.20.0/24";
                gateway = "192.168.20.1";
                dhcpRange = { start = "192.168.20.100"; end = "192.168.20.191"; };
            };
            iot = {
                id = 30;
                subnet = "192.168.30.0/24";
                gateway = "192.168.30.1";
                dhcpRange = { start = "192.168.30.100"; end = "192.168.30.191"; };
            };
            home = {
                id = 40;
                subnet = "192.168.40.0/24";
                gateway = "192.168.40.1";
                dhcpRange = { start = "192.168.40.100"; end = "192.168.40.191"; };
            };
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
            ip = "192.168.20.2";
        };
        hachiko = {
            hostname = "hachiko";
            ip = "192.168.20.3";
            tailscaleIp = "100.75.171.100";
        };
        max = {
            hostname = "max";
            ip = "192.168.20.4";
            tailscaleIp = "100.80.73.118";
            networkStack = {
                name = "max-network-stack";
                ipRange = "192.168.20.192/26";
            };
        };
        nemo = {
            hostname = "nemo";
            ip = "192.168.1.1";
            tailscaleIp = "100.123.84.3";
            wanInterface = "enp1s0";
            lanInterface = "enp2s0";
        };
    };
    ssh_keys = {
        pongo = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHjZD18KxdxjrFiWQm54dP4vDRbZLtMI3C+Pf9LUdHIjjbeAF3AJ3CgQxaA/R1Nao6QmnxrtRp9ljAwrvMhGIK0XgC9rEUcIpNGZH7SB6IYfWreWjITQxyIKgBJuwhR7dTvdaEyINPjLunJtQUJtpCdHio8CAc28aBY6JxUh0dyaUVY0w== pongo";
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
            ip = "192.168.20.200";
            port = 1080;
        };
        plex = {
            ip = "192.168.20.201";
            port = 32400;
            publicSubdomain = "plex";
        };
        qbittorrent = {
            ip = "192.168.20.202";
            port = 8080;
            torrentPort = 6881;
            publicSubdomain = "torrent";
        };
        sabnzbd = {
            ip = "192.168.20.203";
            port = 8080;
            publicSubdomain = "sabnzbd";
        };
        sonarr = {
            ip = "192.168.20.204";
            port = 8989;
            publicSubdomain = "sonarr";
        };
        radarr = {
            ip = "192.168.20.205";
            port = 7878;
            publicSubdomain = "radarr";
        };
        prowlarr = {
            ip = "192.168.20.206";
            port = 9696;
            publicSubdomain = "prowlarr";
        };
        homeAssistant = {
            ip = "192.168.20.207";
            port = 8123;
            publicSubdomain = "homeassistant";
        };
        codeServer = {
            ip = "192.168.20.208";
            port = 8443;
            publicSubdomain = "code";
        };
        n8n = {
            ip = "192.168.20.209";
            port = 5678;
            publicSubdomain = "n8n";
        };
        # cloudflared = {
        #     ip = "192.168.20.210";
        # };
        uptimeKuma = {
            ip = "192.168.20.211";
            port = 3001;
            publicSubdomain = "uptime";
        };
        esphome = {
            ip = "192.168.20.212";
            port = 6052;
            publicSubdomain = "esphome";
        };
        seer = {
            ip = "192.168.20.213";
            port = 5055;
            # publicSubdomain = "seer";
        };
    };
    networkGear = {
        switch1 = {
            ip = "192.168.1.2";
        };
        ap1 = {
            ip = "192.168.1.3";
        };
    };
    iotDevices = {
        smart-switch-1 = {
            ip = "192.168.30.2";
        };
        smart-switch-2 = {
            ip = "192.168.30.3";
        };
        smart-switch-3 = {
            ip = "192.168.30.4";
        };
        smart-switch-4 = {
            ip = "192.168.30.5";
        };
    };
}