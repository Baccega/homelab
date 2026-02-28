# Firewall configuration for the router
# Uses nftables for VLAN-aware filtering and inter-VLAN routing policy
#
# Policy:
# - VLAN 1 (admin): can see everything
# - VLAN 20 (server): isolated from other VLANs (servers can talk to each other);
#   exception: Home Assistant can talk to IoT and home
# - VLAN 30 (iot): isolated from each other and other VLANs; internet + to/from Home Assistant
# - VLAN 40 (home): isolated from server/IoT except Home Assistant; home can talk to home
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
  wanInterface = constants.hosts.nemo.wanInterface;
  lanInterface = constants.hosts.nemo.lanInterface;
  homeAssistantIp = constants.services.homeAssistant.ip;
in
{
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          ct state established,related accept
          ct state invalid drop

          iifname "lo" accept

          # Trust all internal interfaces (admin LAN + VLANs + Tailscale)
          iifname "${lanInterface}" accept
          iifname "vlan20" accept
          iifname "vlan30" accept
          iifname "vlan40" accept
          iifname "tailscale0" accept

          ip protocol icmp accept
          ip6 nexthdr icmpv6 accept

          # Allow Tailscale traffic
          udp dport 41641 accept

          log prefix "nftables-drop: " drop
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state established,related accept
          ct state invalid drop

          # Admin (VLAN 1) has full access to everything
          iifname "${lanInterface}" accept

          # Server (VLAN 20): internet + same VLAN only; HA can reach IoT and home
          iifname "vlan20" oifname "${wanInterface}" accept
          iifname "vlan20" oifname "vlan20" accept
          iifname "vlan20" oifname "vlan30" ip saddr ${homeAssistantIp} accept
          iifname "vlan20" oifname "vlan40" ip saddr ${homeAssistantIp} accept

          # IoT (VLAN 30): internet + to/from Home Assistant only (no same-VLAN, no home)
          iifname "vlan30" oifname "${wanInterface}" accept
          iifname "vlan30" oifname "vlan20" ip daddr ${homeAssistantIp} accept

          # Home (VLAN 40): internet, same VLAN, and Home Assistant only
          iifname "vlan40" oifname "${wanInterface}" accept
          iifname "vlan40" oifname "vlan40" accept
          iifname "vlan40" oifname "vlan20" ip daddr ${homeAssistantIp} accept

          # Tailscale has full access
          iifname "tailscale0" accept
          oifname "tailscale0" accept

          log prefix "nftables-forward-drop: " drop
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }
    '';
  };
}
