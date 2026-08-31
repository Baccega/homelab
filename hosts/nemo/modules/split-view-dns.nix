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
  resolveIp = _: constants.hosts.nemo.ip;
  namedServices = lib.filter (service: service ? subdomain) (lib.attrValues constants.services);
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server = constants.network.dns;
      # Do not use /etc/resolv.conf as upstream
      no-resolv = true;
      domain-needed = true;
      bogus-priv = true;
      no-poll = true;
      cache-size = 1000;
      listen-address = listenAddresses;
      local = map (
        service: "/${service.subdomain}.${constants.network.publicDomain}/"
      ) namedServices;
      address = map (
        service:
        "/${service.subdomain}.${constants.network.publicDomain}/${resolveIp service}"
      ) namedServices;
      conf-file = [ "/etc/dnsmasq-conf.conf" ];
    };
  };

  # Bounce DNS on every Nemo rebuild so LAN clients pick up fresh state.
  systemd.services.dnsmasq.restartTriggers = [ config.system.build.toplevel ];
}
