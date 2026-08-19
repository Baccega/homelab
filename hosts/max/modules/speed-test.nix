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
  homelab.oci-containers.speedtest = {
    image = "docker.io/openspeedtest/latest@sha256:1745e913f596fe98882b286a67751efdae74774e9caa742a4934bb056e8748d2";

    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.speedtest.ip}"
    ];

    # We proxy externally via Nemo/Caddy, so avoid OpenSpeedTest trying to manage its own TLS.
    environment = {
      ENABLE_LETSENCRYPT = "false";
    };
  };

  systemd.services.podman-speedtest = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };
}

