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
  virtualisation.oci-containers.containers.beszel-agent = {
    image = "docker.io/henrygd/beszel-agent:latest";
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
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-beszel-agent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
  };
}
