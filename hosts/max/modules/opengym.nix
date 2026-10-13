# openGym on Max: web (nginx + SPA) and api (passkeys + JSON files).
# Caddy on Nemo terminates TLS for opengym.baccegasandro.dev and proxies to
# the web container; nginx there proxies /api to the api container by IP
# (ipvlan has no Docker DNS at 127.0.0.11, which the image otherwise uses).
# Do not put Cloudflare Access in front of this hostname: passkeys and the
# PWA need the real origin. Register a profile first, then lock sign-up with
# ADMIN_UIDS / INVITE_ONLY if you want it private.
#
# Images come from GHCR (what upstream docker-compose.yml pulls). GitLab's
# registry is a mirror and often lags or drops digests that GHCR still has.
# From v1.4.0 the exercise media ship inside the web image.
{
  config,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/opengym/data";

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
      absolute_redirect off;

      add_header X-Frame-Options "DENY" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header Referrer-Policy "same-origin" always;
      add_header Content-Security-Policy "frame-ancestors 'none'" always;

      location ^~ /api/ {
        client_max_body_size 5m;
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

      location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|webp|avif|mp4)$ {
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
    image = "ghcr.io/duartesantos8/opengym-api:1.4.1@sha256:4bc07fe7d1f05a57c0fa25da3563d54dfe27223506637d67fc64088a2a2f140b";
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
    image = "ghcr.io/duartesantos8/opengym-web:1.4.1@sha256:e32cae9d2f4aad0c5e1b7888c9bfc712b2306ddfe3c65bc4cfefd4b0002e86d3";
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
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.opengym.ip}"
    ];
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
    after = [
      "sops-nix.service"
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
