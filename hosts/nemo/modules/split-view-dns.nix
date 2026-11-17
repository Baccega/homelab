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
  namedServices = lib.filter (service: service ? subdomain) (lib.attrValues constants.services);
  serviceHostnames =
    service:
    map (name: "${name}.${constants.network.publicDomain}") (
      [ service.subdomain ] ++ (service.aliases or [ ])
    );
  publishedHostnames = lib.concatMap serviceHostnames namedServices;
  resolveIp = constants.hosts.nemo.ip;
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
      local = map (hostname: "/${hostname}/") publishedHostnames;
      address = map (hostname: "/${hostname}/${resolveIp}") publishedHostnames;
      conf-file = [ "/etc/dnsmasq-conf.conf" ];
    };
  };

  # Restart when the published hostname set changes (new service/subdomain).
  # Do not use config.system.build.toplevel: that unit is part of toplevel, so
  # evaluation loops.
  systemd.services.dnsmasq.restartTriggers = [
    (builtins.toJSON publishedHostnames)
  ];
}
