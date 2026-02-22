# Firewall configuration for the router
# Uses nftables for VLAN-aware filtering and inter-VLAN routing policy
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

          iifname "${wanInterface}" tcp dport 22 accept
          udp dport 41641 accept

          log prefix "nftables-drop: " drop
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state established,related accept
          ct state invalid drop

          # Admin (LAN) has full access to everything
          iifname "${lanInterface}" accept

          # Servers can reach the internet
          iifname "vlan20" oifname "${wanInterface}" accept

          # Home can reach internet, servers, and IoT
          iifname "vlan40" oifname "${wanInterface}" accept
          iifname "vlan40" oifname "vlan20" accept
          iifname "vlan40" oifname "vlan30" accept

          # IoT can reach servers (Home Assistant) but not the internet
          iifname "vlan30" oifname "vlan20" accept

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
