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
    image = "docker.io/cloudflare/cloudflared:latest@sha256:004d843fa5fdc3103983fd580ee19fab4a8fa98add31f87249c1659e848c98e0";
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
