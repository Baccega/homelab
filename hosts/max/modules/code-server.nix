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
      config.sops.secrets.code-server-env.path
    ];
    environment = {
      DEFAULT_WORKSPACE = "${constants.users.sandro.home}";
    };
    volumes = [
      "${constants.users.sandro.home}/code-server:/config"
      "${constants.users.sandro.home}:${constants.users.sandro.home}"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.codeServer.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-code-server = {
    wantedBy = [ "multi-user.target" ];
    after = [ "create-podman-network-${constants.hosts.max.networkStack.name}.service" ];
  };
}

