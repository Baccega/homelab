# Beszel agent on Nemo
# Reports host metrics to the hub running on Max. Uses host networking so the
# agent can read the real NIC counters; nftables already trusts internal
# interfaces, so no extra firewall rule is needed for the hub to reach :45876.
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
  homelab.oci-containers.beszel-agent = {
    image = "docker.io/henrygd/beszel-agent:latest@sha256:8874e2c53f9de5e063a6a80d6b617e20fa593ac5dc4eb4c6ce1f912f510f38f8";
    environment = {
      LISTEN = toString constants.services.beszel.agentPort;
      HUB_URL = "http://${constants.services.beszel.ip}:${toString constants.services.beszel.port}";
    };
    environmentFiles = [
      config.sops.secrets.nemo-beszel-env.path
    ];
    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
    extraOptions = [
      "--network=host"
    ];
  };

  systemd.services.podman-beszel-agent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
  };
}
