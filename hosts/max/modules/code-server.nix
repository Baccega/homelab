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
  networking.firewall.allowedTCPPorts = [ 
    constants.services.codeServer.port
  ];

  virtualisation.oci-containers.containers.code-server = {
    image = "lscr.io/linuxserver/code-server:latest";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.code-server-password.path
    ];
    environment = {
      DEFAULT_WORKSPACE = "${constants.users.sandro.home}";
      PROXY_DOMAIN = "code.baccegasandro.dev";
    };
    volumes = [
      "${constants.users.sandro.home}/code-server:/config"
      "${constants.users.sandro.home}:${constants.users.sandro.home}"
    ];
    networks = [ constants.network.maxNetworkStack.name ];
    extraOptions = [
      "--ip=${constants.services.codeServer.ip}"
    ];
  };

  systemd.services.podman-code-server = {
    wantedBy = [ "multi-user.target" ];
    after = [ "podman-create-network-${constants.network.maxNetworkStack.name}.service" ];
  };
}

