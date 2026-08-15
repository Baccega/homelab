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
  homelab.oci-containers.cloudflared = {
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
    ];
  };
}
