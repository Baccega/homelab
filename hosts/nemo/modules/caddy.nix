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
  services = lib.attrValues constants.services;
  namedServices = lib.filter (service: service ? subdomain) services;

  serviceHostname =
    service: "${service.subdomain}.${constants.network.publicDomain}";

  siteAddresses =
    service:
    lib.optional (service.exposure == "internet") "http://${serviceHostname service}"
    ++ [ (serviceHostname service) ];

  caddyfileContent = lib.concatStringsSep "\n" ([
    "{"
    "  auto_https disable_redirects"
    "}"
    ""
    "(cloudflare_tls) {"
    "  tls {"
    "    dns cloudflare ${config.sops.placeholder.cloudflare-api-token}"
    "    resolvers ${resolvers}"
    "  }"
    "}"
    ""
  ] ++ lib.concatMap (service: [
    "${lib.concatStringsSep ", " (siteAddresses service)} {"
    "  import cloudflare_tls"
    "  reverse_proxy ${service.ip}:${toString service.port}"
    "}"
    ""
  ]) namedServices) + "\n";
in
{
  assertions = [
    {
      assertion = lib.all (
        service:
        service ? exposure && builtins.elem service.exposure [
          "lan"
          "internet"
        ]
      ) services;
      message = "Every service must set exposure to either \"lan\" or \"internet\".";
    }
  ];

  sops.templates."Caddyfile" = {
    content = caddyfileContent;
    owner = "caddy";
    mode = "0640";
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
      hash = "sha256-to0fhW7LWBocw1ccpPQ7e2nod7iJO9gkWZpjHsZDeu4=";
    };
    configFile = config.sops.templates."Caddyfile".path;
  };

  systemd.services.caddy = {
    after = lib.mkAfter [ "sops-nix.service" ];
    restartTriggers = lib.mkAfter [ config.sops.templates."Caddyfile".path ];
  };
}
