# Tailscale configuration for subnet routing
# This makes the entire local network accessible via Tailscale
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;
in
{
  # Enable Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";  # Enable subnet routing capabilities
    openFirewall = true;            # Allow Tailscale traffic through firewall
  };

  # Ensure IP forwarding is enabled (also set in main config, but explicit here)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Create a systemd service to advertise routes after Tailscale is up
  # You'll need to authenticate first with: sudo tailscale up
  # Then run: sudo tailscale set --advertise-routes=192.168.1.0/24 --accept-routes
  #
  # Note: You must approve the subnet routes in the Tailscale admin console:
  # https://login.tailscale.com/admin/machines
  
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Wait for tailscaled to be ready
      sleep 2
      
      # Check if already authenticated
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"')
      
      if [ "$status" = "Running" ]; then
        echo "Tailscale is already connected, advertising routes..."
        ${pkgs.tailscale}/bin/tailscale set \
          --advertise-routes=${constants.network.subnet} \
          --accept-routes \
          --advertise-exit-node
        echo "Routes advertised. Remember to approve them in the Tailscale admin console."
      else
        echo "Tailscale is not authenticated yet."
        echo "Please run: sudo tailscale up --advertise-routes=${constants.network.subnet} --accept-routes --advertise-exit-node"
        echo "Then approve the routes in the Tailscale admin console."
      fi
    '';
  };

  # Add tailscale to system packages for easy CLI access
  environment.systemPackages = [ pkgs.tailscale ];
}
