# Split-view DNS on Nemo using dnsmasq
# Resolves configured hostnames to LAN IPs; all other queries forwarded to upstream DNS.
# DHCP hands out Nemo's gateway per VLAN as DNS so LAN clients use this resolver.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  # Listen on localhost (for Nemo itself) and each VLAN gateway so clients use us
  listenAddresses = [
    "127.0.0.1"
    constants.hosts.nemo.ip
    constants.network.vlans.servers.gateway
    constants.network.vlans.iot.gateway
    constants.network.vlans.home.gateway
  ];
  resolveIp = e:
    if e ? targetService then constants.services.${e.targetService}.ip
    else constants.hosts.${e.targetHost}.ip;
  # Template: placeholder is substituted at activation with the decrypted public-domain secret
  splitViewConfContent = lib.concatStringsSep "\n" (
    map (e: "address=/${e.subdomain}.${config.sops.placeholder.public-domain}/${resolveIp e}") constants.network.splitViewDns
  ) + "\n";
in
{
  sops.templates."dnsmasq-split-view.conf" = {
    content = splitViewConfContent;
    mode = "0644";
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    servers = constants.network.dns;
    settings = {
      domain-needed = true;
      bogus-priv = true;
      no-poll = true;
      cache-size = 1000;
      listen-address = listenAddresses;
      conf-file = [
        "/etc/dnsmasq-conf.conf"
      ] ++ lib.optionals (constants.network.splitViewDns != []) [
        config.sops.templates."dnsmasq-split-view.conf".path
      ];
    };
  };

  systemd.services.dnsmasq = {
    after = lib.mkAfter [ "sops-nix.service" ];
    restartTriggers = lib.mkAfter [ config.sops.templates."dnsmasq-split-view.conf".path ];
  };
}
