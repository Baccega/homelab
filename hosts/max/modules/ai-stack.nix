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
  homelab.oci-containers.ollama = {
    image = "docker.io/ollama/ollama:latest@sha256:32931b46719f673c05fdbaa81ccb26da18ea4a1c57590a754874ab28ba269eb2";
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
    ];
  };

  homelab.oci-containers.open-webui = {
    image = "ghcr.io/open-webui/open-webui:latest@sha256:1a6399d237dc392a2313e0ca826020b3fd5d22536357840eb63393d18dc8b924";
    environment = {
      OLLAMA_BASE_URL = "http://${constants.services.ollama.ip}:${toString constants.services.ollama.port}";
      WEBUI_URL = "https://${constants.services.openWebui.subdomain}.${constants.network.publicDomain}";
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
