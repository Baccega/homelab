# openGym on Max: web (nginx + SPA) and api (passkeys + JSON files).
# Caddy on Nemo terminates TLS for opengym.baccegasandro.dev and proxies to
# the web container; nginx there proxies /api to the api container by IP
# (ipvlan has no Docker DNS at 127.0.0.11, which the image otherwise uses).
# Do not put Cloudflare Access in front of this hostname: passkeys and the
# PWA need the real origin. Register a profile first, then lock sign-up with
# ADMIN_UIDS / INVITE_ONLY if you want it private.
{
  config,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/opengym/data";
  mediaDir = "${constants.users.sandro.home}/opengym/media";
  mediaImgDir = "${mediaDir}/img";
  mediaGifDir = "${mediaDir}/gif";

  hostname = "${constants.services.opengym.subdomain}.${constants.network.publicDomain}";
  origin = "https://${hostname}";

  apiUpstream = "http://${constants.services.opengymApi.ip}:${toString constants.services.opengymApi.port}";

  # Upstream template uses Docker's 127.0.0.11 resolver. ipvlan has no such
  # DNS, so /api is proxied to the pinned API IP instead of a service name.
  nginxTemplate = pkgs.writeText "opengym-nginx.conf.template" ''
    server {
      listen ''${NGINX_PORT};
      root /usr/share/nginx/html;
      index index.html;

      add_header X-Frame-Options "DENY" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header Referrer-Policy "same-origin" always;
      add_header Content-Security-Policy "frame-ancestors 'none'" always;

      location ^~ /api/ {
        proxy_pass ${apiUpstream};
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header CF-Connecting-IP "''${CF_CONNECTING_IP}";
      }

      location / {
        try_files $uri $uri/ /index.html;
      }

      location ~* \.(js|css|json|html)$ {
        add_header Cache-Control "no-cache, must-revalidate";
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Content-Security-Policy "frame-ancestors 'none'" always;
      }

      location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|webp|avif)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000, immutable";
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Content-Security-Policy "frame-ancestors 'none'" always;
      }

      gzip on;
      gzip_types text/plain text/css application/json application/javascript image/svg+xml;
      gzip_vary on;
      gzip_min_length 1024;
    }
  '';
in
{
  homelab.oci-containers.opengym-api = {
    image = "registry.gitlab.com/duartesantos8/opengym/api:latest@sha256:ea111626ba222beb6f0de29f2b458272b2e51b0e84a00a806c7ff2335bd52c0c";
    environment = {
      PORT = toString constants.services.opengymApi.port;
      DATA_DIR = "/data";
      RP_ID = hostname;
      ORIGIN = origin;
      RP_NAME = "openGym";
      VAPID_SUBJECT = origin;
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${dataDir}:/data"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.opengymApi.ip}"
    ];
  };

  homelab.oci-containers.opengym = {
    image = "registry.gitlab.com/duartesantos8/opengym/web:latest@sha256:cbba591c7441cf297bdbedb48bcd0448367407e84c8829c993d1cae3afad94a6";
    environment = {
      NGINX_PORT = toString constants.services.opengym.port;
      # Cloudflare Tunnel overwrites this header; leave it through so the
      # activity log can see the real client on internet requests.
      CF_CONNECTING_IP = "$http_cf_connecting_ip";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${nginxTemplate}:/etc/nginx/templates/default.conf.template:ro"
      "${mediaImgDir}:/usr/share/nginx/html/img:ro"
      "${mediaGifDir}:/usr/share/nginx/html/gif:ro"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.opengym.ip}"
    ];
  };

  # Exercise images/GIFs (~140 MB) from hasaneyldrm/exercises-dataset. openGym
  # does not ship them; first boot clones upstream once. Re-downloadable, so
  # they are not part of the NAS backup.
  systemd.services.opengym-media = {
    description = "Download openGym exercise media";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "15min";
      ExecStart = pkgs.writeShellScript "opengym-media" ''
        set -euo pipefail
        mkdir -p "${mediaImgDir}" "${mediaGifDir}"
        if [ -n "$(ls -A "${mediaImgDir}" 2>/dev/null)" ]; then
          echo "openGym exercise media already present, skipping"
          exit 0
        fi
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        echo "Downloading exercise media (~140 MB) from github.com/hasaneyldrm/exercises-dataset"
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset "$tmp/ds"
        cp "$tmp/ds/images/"*.jpg "${mediaImgDir}/"
        cp "$tmp/ds/videos/"*.gif "${mediaGifDir}/"
        chown -R ${toString constants.users.alfred.uid}:${toString constants.groups.users} "${mediaDir}"
        echo "openGym exercise media ready"
      '';
    };
  };

  systemd.services.podman-opengym-api = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-opengym.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.podman-opengym = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "opengym-media.service" ];
    after = [
      "sops-nix.service"
      "opengym-media.service"
      "podman-opengym-api.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "opengym";
        nfsMount = constants.mountPoints.configurations.path;
        source = "opengym";
        target = dataDir;
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "opengym";
        source = dataDir;
        nfsMount = constants.mountPoints.configurations.path;
        destination = "opengym";
        schedule = "daily";
      }
    ];
  };
}
