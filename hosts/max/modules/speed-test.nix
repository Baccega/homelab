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
    # iPerf3-WebUI container
  homelab.oci-containers.speedtest = {
    image = "ghcr.io/maddydev-glitch/iperf3-webui@sha256:b0b395d545a2451639b6be8fb4d0e50e5c5029f559a363aca4dacae8993c98b7";

    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.speedtest.ip}"
    ];
  };

  systemd.services.podman-speedtest = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };
}

