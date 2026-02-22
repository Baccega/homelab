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
          interfaces = [
            constants.hosts.nemo.lanInterface
            "vlan20"
            "vlan30"
            "vlan40"
          ];
        };

        lease-database = {
          type = "memfile";
          persist = true;
          name = "/var/lib/kea/dhcp4.leases";
        };

        subnet4 = [
          # VLAN 1 - Admin / Management
          {
            id = 1;
            subnet = constants.network.vlans.admin.subnet;
            pools = [
              {
                pool = "${constants.network.vlans.admin.dhcpRange.start} - ${constants.network.vlans.admin.dhcpRange.end}";
              }
            ];
            option-data = [
              { name = "routers"; data = constants.network.vlans.admin.gateway; }
              { name = "domain-name-servers"; data = dnsServers; }
              { name = "domain-name"; data = "lan"; }
            ];
            reservations = [
              {
                hw-address = config.sops.placeholder.switch1-bridge1-interface;
                ip-address = constants.network.switch1.ip;
              }
              {
                hw-address = config.sops.placeholder.ap1-lan-interface;
                ip-address = constants.network.ap1.ip;
              }
            ];
          }

          # VLAN 20 - Servers
          {
            id = 20;
            subnet = constants.network.vlans.servers.subnet;
            pools = [
              {
                pool = "${constants.network.vlans.servers.dhcpRange.start} - ${constants.network.vlans.servers.dhcpRange.end}";
              }
            ];
            option-data = [
              { name = "routers"; data = constants.network.vlans.servers.gateway; }
              { name = "domain-name-servers"; data = dnsServers; }
              { name = "domain-name"; data = "lan"; }
            ];
            reservations = [
              {
                hw-address = config.sops.placeholder.max-eno1-interface;
                ip-address = constants.hosts.max.ip;
              }
              {
                hw-address = config.sops.placeholder.hachiko-lan1-interface;
                ip-address = constants.hosts.hachiko.ip;
              }
              # {
              #   hw-address = config.sops.placeholder.balto-lan-interface;
              #   ip-address = constants.hosts.balto.ip;
              # }
              {
                hw-address = config.sops.placeholder.laika-wlp2s0-interface;
                ip-address = constants.hosts.laika.ip;
              }
            ];
          }

          # VLAN 30 - IoT
          {
            id = 30;
            subnet = constants.network.vlans.iot.subnet;
            pools = [
              {
                pool = "${constants.network.vlans.iot.dhcpRange.start} - ${constants.network.vlans.iot.dhcpRange.end}";
              }
            ];
            option-data = [
              { name = "routers"; data = constants.network.vlans.iot.gateway; }
              { name = "domain-name-servers"; data = dnsServers; }
              { name = "domain-name"; data = "lan"; }
            ];
          }

          # VLAN 40 - Home
          {
            id = 40;
            subnet = constants.network.vlans.home.subnet;
            pools = [
              {
                pool = "${constants.network.vlans.home.dhcpRange.start} - ${constants.network.vlans.home.dhcpRange.end}";
              }
            ];
            option-data = [
              { name = "routers"; data = constants.network.vlans.home.gateway; }
              { name = "domain-name-servers"; data = dnsServers; }
              { name = "domain-name"; data = "lan"; }
            ];
          }
        ];
      };
    };
    mode = "0644";
  };

  # Use the template as config file instead of settings
  services.kea.dhcp4 = {
    enable = true;
    configFile = config.sops.templates."kea-dhcp4.conf".path;
  };

  systemd.services.kea-dhcp4-server = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    restartTriggers = [ config.sops.templates."kea-dhcp4.conf".path ];
  };
}
