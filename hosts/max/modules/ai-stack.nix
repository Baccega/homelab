# Local AI stack on Max
# Ollama runs the local models (GPU-accelerated via the NVIDIA container toolkit)
# and Open WebUI provides a management/chat UI on top of it. This stack is kept
# separate from Paperless so the document pipeline and the model runtime can be
# managed independently.
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
  virtualisation.oci-containers.containers.ollama = {
    image = "docker.io/ollama/ollama:latest";
    environment = {
      OLLAMA_HOST = "0.0.0.0:${toString constants.services.ollama.port}";
      OLLAMA_KEEP_ALIVE = "15m";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "all";
      CUDA_VISIBLE_DEVICES = "0";
      OLLAMA_GPU = "0";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/ollama:/root/.ollama"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.ollama.ip}"
      "--device=nvidia.com/gpu=all"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  virtualisation.oci-containers.containers.open-webui = {
    image = "ghcr.io/open-webui/open-webui:latest";
    environment = {
      OLLAMA_BASE_URL = "http://${constants.services.ollama.ip}:${toString constants.services.ollama.port}";
      WEBUI_URL = "https://${constants.services.openWebui.publicSubdomain}.${constants.network.publicDomain}";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.ai-stack-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/open-webui:/app/backend/data"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.openWebui.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  systemd.services.podman-ollama = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.podman-open-webui = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-open-webui.service"
      "podman-ollama.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  # Ollama models are large and re-downloadable, so they are intentionally not
  # synced or backed up. Only the Open WebUI config/state is persisted.
  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "open-webui";
        nfsMount = constants.mountPoints.configurations.path;
        source = "open-webui";
        target = "${constants.users.sandro.home}/open-webui";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "open-webui";
        source = "${constants.users.sandro.home}/open-webui";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "open-webui";
        schedule = "daily";
      }
    ];
  };
}
