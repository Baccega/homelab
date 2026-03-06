# Caddy reverse proxy on Nemo
# Routes subdomain requests to the correct service IP:port.
# Serves both LAN clients (via split-view DNS) and external traffic (via Cloudflare Tunnel).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  resolvers = lib.concatStringsSep " " constants.network.dns;

  caddyfileContent = lib.concatStringsSep "\n" ([
    "(cloudflare_tls) {"
    "  tls {"
    "    dns cloudflare ${config.sops.placeholder.cloudflare-api-token}"
    "    resolvers ${resolvers}"
    "  }"
    "}"
    ""
  ] ++ lib.concatMap (e: let
    service = constants.services.${e.targetService};
  in [
    "${e.subdomain}.${config.sops.placeholder.public-domain} {"
    "  import cloudflare_tls"
    "  reverse_proxy ${service.ip}:${toString service.port}"
    "}"
    ""
  ]) constants.network.splitViewDns) + "\n";
in
{
  sops.templates."Caddyfile" = {
    content = caddyfileContent;
    owner = "caddy";
    mode = "0640";
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
      hash = "sha256-bJO2RIa6hYsoVl3y2L86EM34Dfkm2tlcEsXn2+COgzo=";
    };
    configFile = config.sops.templates."Caddyfile".path;
  };

  systemd.services.caddy = {
    after = lib.mkAfter [ "sops-nix.service" ];
    restartTriggers = lib.mkAfter [ config.sops.templates."Caddyfile".path ];
  };
}
