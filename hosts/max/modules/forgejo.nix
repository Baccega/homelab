# Forgejo on Max
# LAN-only git host at git.baccegasandro.dev (Caddy + split-view DNS on Nemo).
# HTTPS clone/push goes through Caddy; built-in SSH listens on the container IP.
{
  config,
  ...
}:
let
  constants = import ../../../constants.nix;

  hostname = "${constants.services.forgejo.subdomain}.${constants.network.publicDomain}";
  rootUrl = "https://${hostname}/";
  dataDir = "${constants.users.sandro.home}/forgejo";
in
{
  homelab.oci-containers.forgejo = {
    image = "codeberg.org/forgejo/forgejo:17@sha256:fcd19ff4ebc85fb098a67e8e1d0d5a84d07dd6e8a23edcfdfd5b71a6178953be";
    environment = {
      FORGEJO__server__DOMAIN = hostname;
      FORGEJO__server__ROOT_URL = rootUrl;
      FORGEJO__server__HTTP_PORT = toString constants.services.forgejo.port;
      FORGEJO__server__START_SSH_SERVER = "true";
      # SSH clone URLs use the container IP; DNS for the hostname points at Caddy.
      FORGEJO__server__SSH_DOMAIN = constants.services.forgejo.ip;
      FORGEJO__server__SSH_PORT = toString constants.services.forgejo.sshPort;
      FORGEJO__server__SSH_LISTEN_PORT = toString constants.services.forgejo.sshPort;
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${dataDir}:/data"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.forgejo.ip}"
    ];
  };

  systemd.services.podman-forgejo = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-forgejo.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "forgejo";
        nfsMount = constants.mountPoints.configurations.path;
        source = "forgejo";
        target = dataDir;
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "forgejo";
        source = dataDir;
        nfsMount = constants.mountPoints.configurations.path;
        destination = "forgejo";
        schedule = "daily";
      }
    ];
  };
}
