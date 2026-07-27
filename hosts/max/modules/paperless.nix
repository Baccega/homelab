# Paperless-ngx on Max
# Document archive with OCR and full-text search. Postgres and Redis run on Max
# in their own modules (postgres.nix / redis.nix) and are reached over the shared
# ipvlan network by IP. Gotenberg and Tika handle Office/email document
# conversion and text extraction. Paperless-GPT adds local-LLM (Ollama) based OCR
# on top, driven by tags.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  paperlessUrl = "https://${constants.services.paperless.publicSubdomain}.${config.sops.placeholder.public-domain}";

  gotenbergEndpoint = "http://${constants.services.paperlessGotenberg.ip}:${toString constants.services.paperlessGotenberg.port}";
  tikaEndpoint = "http://${constants.services.paperlessTika.ip}:${toString constants.services.paperlessTika.port}";
  ollamaHost = "http://${constants.services.ollama.ip}:${toString constants.services.ollama.port}";
  paperlessBaseUrl = "http://${constants.services.paperless.ip}:${toString constants.services.paperless.port}";
in
{
  networking.firewall.allowedTCPPorts = [
    constants.services.paperless.port
    # constants.services.paperlessGpt.port
  ];

  # The public URL embeds the (sops-managed) domain, so keep it out of the nix
  # store by rendering it through a sops template.
  sops.templates."paperless.env".content = ''
    PAPERLESS_URL=${paperlessUrl}
  '';
  # sops.templates."paperless-gpt.env".content = ''
  #   PAPERLESS_PUBLIC_URL=${paperlessUrl}
  # '';

  virtualisation.oci-containers.containers.paperless = {
    image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
    environment = {
      USERMAP_UID = toString constants.users.alfred.uid;
      USERMAP_GID = toString constants.groups.users;
      PAPERLESS_TIME_ZONE = "Europe/Vienna";
      PAPERLESS_CONSUMER_DELETE_DUPLICATES = "true";

      # Database and queue run on Max (postgres.nix / redis.nix).
      PAPERLESS_DBHOST = constants.services.postgres.ip;
      PAPERLESS_DBPORT = toString constants.services.postgres.port;
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";

      # Office/email document conversion + text extraction.
      PAPERLESS_TIKA_ENABLED = "1";
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT = gotenbergEndpoint;
      PAPERLESS_TIKA_ENDPOINT = tikaEndpoint;

      PAPERLESS_AI_ENABLED = "True";
      PAPERLESS_AI_LLM_BACKEND = "ollama";
      PAPERLESS_AI_LLM_MODEL = "gemma3:4b";
      PAPERLESS_AI_LLM_API_KEY = "";
      PAPERLESS_AI_LLM_ENDPOINT = ollamaHost;
      PAPERLESS_AI_LLM_ALLOW_INTERNAL_ENDPOINTS = "true";
      PAPERLESS_AI_LLM_EMBEDDING_BACKEND="ollama";
      PAPERLESS_AI_LLM_EMBEDDING_MODEL = "nomic-embed-text";
      PAPERLESS_AI_LLM_EMBEDDING_ENDPOINT = ollamaHost;

      PAPERLESS_OCR_LANGUAGE = "ita+deu+eng";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.paperless-env.path
      config.sops.templates."paperless.env".path
    ];
    volumes = [
      "${constants.users.sandro.home}/paperless/data:/usr/src/paperless/data"
      "${constants.users.sandro.home}/paperless/media:/usr/src/paperless/media"
      "${constants.users.sandro.home}/paperless/export:/usr/src/paperless/export"
      "${constants.users.sandro.home}/paperless/consume:/usr/src/paperless/consume"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.paperless.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  virtualisation.oci-containers.containers.paperless-gotenberg = {
    image = "docker.io/gotenberg/gotenberg:8.25";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    cmd = [
      "gotenberg"
      "--chromium-disable-javascript=true"
      "--chromium-allow-list=file:///tmp/.*"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.paperlessGotenberg.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  virtualisation.oci-containers.containers.paperless-tika = {
    image = "docker.io/apache/tika:latest";
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.paperlessTika.ip}"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  # virtualisation.oci-containers.containers.paperless-gpt = {
  #   image = "docker.io/icereed/paperless-gpt:latest";
  #   environment = {
  #     PAPERLESS_BASE_URL = paperlessBaseUrl;
  #     PAPERLESS_INSECURE_SKIP_VERIFY = "true";

  #     # Text metadata model.
  #     LLM_PROVIDER = "ollama";
  #     LLM_MODEL = "gemma3:4b";
  #     OLLAMA_HOST = ollamaHost;
  #     OLLAMA_CONTEXT_LENGTH = "8192";
  #     TOKEN_LIMIT = "1000";
  #     LLM_LANGUAGE = "Italian";

  #     # Vision model used for LLM-based OCR.
  #     OCR_PROVIDER = "llm";
  #     VISION_LLM_PROVIDER = "ollama";
  #     VISION_LLM_MODEL = "granite3.2-vision";

  #     AUTO_OCR_TAG = "paperless-gpt-ocr-auto";
  #     AUTO_TAG = "paperless-gpt-auto";
  #     MANUAL_TAG = "paperless-gpt-manual";
  #     PDF_OCR_TAGGING = "true";
  #     PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete";
  #     PDF_UPLOAD = "false";
  #     LOG_LEVEL = "info";
  #   };
  #   environmentFiles = [
  #     config.sops.secrets.max-docker-env.path
  #     config.sops.secrets.paperless-env.path
  #     config.sops.templates."paperless-gpt.env".path
  #   ];
  #   volumes = [
  #     "${constants.users.sandro.home}/paperless/paperless-gpt-prompts:/app/prompts"
  #   ];
  #   networks = [ constants.hosts.max.networkStack.name ];
  #   extraOptions = [
  #     "--ip=${constants.services.paperlessGpt.ip}"
  #     "--label=io.containers.autoupdate=registry"
  #   ];
  # };

  systemd.services.podman-paperless-gotenberg = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.podman-paperless-tika = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.podman-paperless = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-paperless.service"
      "podman-postgres.service"
      "podman-redis.service"
      "podman-paperless-gotenberg.service"
      "podman-paperless-tika.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
    restartTriggers = [ config.sops.templates."paperless.env".path ];
  };

  # systemd.services.podman-paperless-gpt = {
  #   wantedBy = [ "multi-user.target" ];
  #   after = [
  #     "sops-nix.service"
  #     "podman-paperless.service"
  #     "podman-ollama.service"
  #     "create-podman-network-${constants.hosts.max.networkStack.name}.service"
  #   ];
  #   restartTriggers = [ config.sops.templates."paperless-gpt.env".path ];
  # };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "paperless";
        nfsMount = constants.mountPoints.configurations.path;
        source = "paperless";
        target = "${constants.users.sandro.home}/paperless";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "paperless";
        source = "${constants.users.sandro.home}/paperless";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "paperless";
        schedule = "daily";
      }
    ];
  };
}
