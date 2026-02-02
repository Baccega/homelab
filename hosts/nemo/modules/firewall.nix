# Firewall configuration for the router
# This module configures nftables-based firewall rules
#
# NOTE: This module is currently disabled in configuration.nix
# Uncomment the import when ready to enable the firewall
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
  # # Enable the NixOS firewall
  # networking.firewall = {
  #   enable = true;
  #   
  #   # Allow these ports on WAN interface
  #   allowedTCPPorts = [
  #     22    # SSH
  #   ];
  #   
  #   allowedUDPPorts = [
  #     41641 # Tailscale
  #   ];
  #   
  #   # Trust the LAN interface completely
  #   trustedInterfaces = [ lanInterface "tailscale0" ];
  #   
  #   # Enable connection tracking helpers
  #   connectionTrackingModules = [ "ftp" ];
  #   
  #   # Log dropped packets (useful for debugging)
  #   logRefusedConnections = true;
  #   logRefusedPackets = false;
  #   
  #   # Additional iptables rules for NAT
  #   extraCommands = ''
  #     # Allow established and related connections
  #     iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  #     
  #     # Allow ICMP (ping)
  #     iptables -A INPUT -p icmp -j ACCEPT
  #     
  #     # Drop invalid packets
  #     iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
  #     
  #     # Protect against SYN floods
  #     iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
  #   '';
  #   
  #   extraStopCommands = ''
  #     iptables -F
  #   '';
  # };

  # Alternative: Use nftables for more modern firewall management
  # networking.nftables = {
  #   enable = true;
  #   ruleset = ''
  #     table inet filter {
  #       chain input {
  #         type filter hook input priority 0; policy drop;
  #         
  #         # Allow established/related
  #         ct state established,related accept
  #         
  #         # Allow loopback
  #         iifname "lo" accept
  #         
  #         # Allow LAN
  #         iifname "${lanInterface}" accept
  #         
  #         # Allow Tailscale
  #         iifname "tailscale0" accept
  #         
  #         # Allow ICMP
  #         ip protocol icmp accept
  #         ip6 nexthdr icmpv6 accept
  #         
  #         # Allow SSH from WAN
  #         iifname "${wanInterface}" tcp dport 22 accept
  #         
  #         # Allow Tailscale UDP
  #         udp dport 41641 accept
  #         
  #         # Log and drop everything else
  #         log prefix "nftables-drop: " drop
  #       }
  #       
  #       chain forward {
  #         type filter hook forward priority 0; policy drop;
  #         
  #         # Allow established/related
  #         ct state established,related accept
  #         
  #         # Allow LAN to WAN
  #         iifname "${lanInterface}" oifname "${wanInterface}" accept
  #         
  #         # Allow LAN to Tailscale
  #         iifname "${lanInterface}" oifname "tailscale0" accept
  #         iifname "tailscale0" oifname "${lanInterface}" accept
  #       }
  #       
  #       chain output {
  #         type filter hook output priority 0; policy accept;
  #       }
  #     }
  #     
  #     table inet nat {
  #       chain postrouting {
  #         type nat hook postrouting priority 100;
  #         
  #         # Masquerade traffic going out WAN
  #         oifname "${wanInterface}" masquerade
  #       }
  #     }
  #   '';
  # };
}
