# DHCP Server configuration using Kea
# This provides DHCP services for the local network
# Uses SOPS templates to inject MAC addresses at runtime
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  dnsServers = builtins.concatStringsSep ", " constants.network.dns;
in
{
  sops.templates."kea-dhcp4.conf" = {
    content = builtins.toJSON {
      Dhcp4 = {
        valid-lifetime = 4000;
        renew-timer = 1000;
        rebind-timer = 2000;

        interfaces-config = {
          interfaces = [ constants.hosts.nemo.lanInterface ];
        };

        lease-database = {
          type = "memfile";
          persist = true;
          name = "/var/lib/kea/dhcp4.leases";
        };

        subnet4 = [
          {
            id = 1;
            subnet = constants.network.subnet;
            pools = [
              {
                pool = "${constants.network.dhcp.rangeStart} - ${constants.network.dhcp.rangeEnd}";
              }
            ];
            option-data = [
              {
                name = "routers";
                data = constants.hosts.nemo.ip;
              }
              {
                name = "domain-name-servers";
                data = dnsServers;
              }
              {
                name = "domain-name";
                data = "lan";
              }
            ];

            reservations = [
              {
                hw-address = config.sops.placeholder.balto-lan-interface;
                ip-address = constants.hosts.balto.ip;
              }
              {
                hw-address = config.sops.placeholder.laika-wlp2s0-interface;
                ip-address = constants.hosts.laika.ip;
              }
              {
                hw-address = config.sops.placeholder.max-eno1-interface;
                ip-address = constants.hosts.max.ip;
              }
              {
                hw-address = config.sops.placeholder.hachiko-lan1-interface;
                ip-address = constants.hosts.hachiko.ip;
              }
            ];
          }
        ];
      };
    };
    owner = "kea";
  };

  # Use the template as config file instead of settings
  services.kea.dhcp4 = {
    enable = true;
    configFile = config.sops.templates."kea-dhcp4.conf".path;
  };

  # Ensure kea service starts after sops-nix renders the template
  systemd.services.kea-dhcp4-server = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    restartTriggers = [ config.sops.templates."kea-dhcp4.conf".path ];
  };
}
