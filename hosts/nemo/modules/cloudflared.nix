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
    image = "docker.io/cloudflare/cloudflared:latest@sha256:faa8e0a1475f137c910be6025f43c8e4092fdd35461b31e19fd1390657a1ff39";
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
