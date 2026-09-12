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
    image = "docker.io/cloudflare/cloudflared:latest@sha256:b269e8abd07a5bf6f3f4be65d5050b2174eca89c56a0241a8ff32a16aec454e4";
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
