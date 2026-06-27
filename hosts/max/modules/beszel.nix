# Beszel monitoring on Max
# Runs the Beszel hub (web UI) on the ipvlan network like the other services,
# plus a local agent. The local agent uses host networking for accurate NIC
# stats and connects to the hub over a shared unix socket, because ipvlan
# containers can't be reached from the host's own network namespace.
# See https://beszel.dev/guide/hub-installation#docker-or-podman
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
    constants.services.beszel.port
  ];

  sops.templates."beszel-hub.env".content =
    "APP_URL=https://${constants.services.beszel.publicSubdomain}.${config.sops.placeholder.public-domain}\n";

  virtualisation.oci-containers.containers.beszel = {
    image = "docker.io/henrygd/beszel:latest";
    environmentFiles = [
      config.sops.templates."beszel-hub.env".path
    ];
    volumes = [
      "${constants.users.sandro.home}/beszel:/beszel_data"
      "/run/beszel:/beszel_socket"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.beszel.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  virtualisation.oci-containers.containers.beszel-agent = {
    image = "docker.io/henrygd/beszel-agent-nvidia:latest";
    environment = {
      # Hub connects in over the shared unix socket; when adding this system in
      # the hub UI, set Host/IP to /beszel_socket/beszel.sock.
      LISTEN = "/beszel_socket/beszel.sock";
      GPU_COLLECTOR = "nvml";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "utility";
    };
    environmentFiles = [
      config.sops.secrets.max-beszel-env.path
    ];
    volumes = [
      "/run/beszel:/beszel_socket"
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];
    extraOptions = [
      "--network=host"
      "--device=nvidia.com/gpu=all"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-beszel = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-beszel.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
    restartTriggers = [ config.sops.templates."beszel-hub.env".path ];
  };

  systemd.services.podman-beszel-agent = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "podman-beszel.service"
    ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "beszel";
        nfsMount = constants.mountPoints.configurations.path;
        source = "beszel";
        target = "${constants.users.sandro.home}/beszel";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "beszel";
        source = "${constants.users.sandro.home}/beszel";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "beszel";
        schedule = "daily";
      }
    ];
  };
}
