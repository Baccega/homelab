# Cloudflared tunnel for secure external access
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
  # Using the NixOS native cloudflared service
  # You'll need to set up the tunnel token in your sops secrets
  # services.cloudflared = {
  #   enable = true;
  #   tunnels = {
  #     "nemo-tunnel" = {
  #       credentialsFile = config.sops.secrets.nemo-cloudflared-credentials.path;
  #       default = "http_status:404";
        
  #       # Add your ingress rules here
  #       # ingress = {
  #       #   "example.domain.com" = "http://localhost:8080";
  #       # };
  #     };
  #   };
  # };

  # systemd.services.podman-cloudflared = {
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "create-podman-network-${constants.network.maxNetworkStack.name}.service" ];
  # };

  # Ensure the secret is available
  # sops.secrets.nemo-cloudflared-credentials = {
  #   sopsFile = ../../../secrets/secrets.json;
    # format = "json";  # Uncomment if using JSON format
  # };

  virtualisation.oci-containers.containers.cloudflared = {
    image = "docker.io/cloudflare/cloudflared:latest";
    environmentFiles = [
      config.sops.secrets.nemo-docker-env.path
      config.sops.secrets.cloudflared-token.path
    ];
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
    ];
  };
}
