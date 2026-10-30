# Uptime Kuma + AutoKuma
# Monitors are generated from constants.services.*.monitoring and synced into
# Kuma by AutoKuma. AutoKuma only manages entities it creates (tracked via its
# own tag); existing hand-made monitors are left alone.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  knownTags = {
    "Main Network - Core" = {
      id = "tag-main-network-core";
      color = "#7C3AED";
    };
    "Main Network - Service" = {
      id = "tag-main-network-service";
      color = "#DB2777";
    };
  };

  defaultType = service: if service ? subdomain then "http" else "port";

  monitoredServices = lib.filterAttrs (
    _name: service: ((service.monitoring or { }).enable or false)
  ) constants.services;

  monitorBody =
    name: service:
    let
      cfg = service.monitoring;
      monitorType = cfg.type or (defaultType service);
      displayName = cfg.name or service.subdomain or name;
      tag = knownTags.${cfg.tag};
      path = cfg.path or "";
      url =
        cfg.url or (
          "https://${service.subdomain}.${constants.network.publicDomain}${path}"
        );
      base = {
        type = monitorType;
        name = displayName;
        interval = cfg.interval or 60;
        max_retries = cfg.maxRetries or 3;
        # Nested structures must be JSON-encoded strings for AutoKuma.
        tag_names = builtins.toJSON [
          { name = tag.id; }
        ];
      };
      withStatus =
        body:
        if cfg ? expectedStatus then
          body // { accepted_statuscodes = toString cfg.expectedStatus; }
        else
          body;
    in
    withStatus (
      if monitorType == "http" then
        base // { inherit url; }
      else if monitorType == "port" then
        base
        // {
          hostname = cfg.hostname or service.ip;
          port = cfg.port or service.port;
        }
      else if monitorType == "ping" then
        base // { hostname = cfg.hostname or service.ip; }
      else
        throw "Unsupported monitoring.type '${monitorType}' for service '${name}' (use http, port, or ping)."
    );

  tagEntityFiles = lib.mapAttrsToList (displayName: tag: {
    name = "${tag.id}.json";
    path = pkgs.writeText "${tag.id}.json" (builtins.toJSON {
      type = "tag";
      name = displayName;
      color = tag.color;
    });
  }) knownTags;

  monitorFiles = lib.mapAttrsToList (name: service: {
    name = "${name}.json";
    path = pkgs.writeText "${name}.json" (builtins.toJSON (monitorBody name service));
  }) monitoredServices;

  staticMonitors = pkgs.runCommand "autokuma-static-monitors" { } ''
    mkdir -p $out
    ${lib.concatMapStrings (file: ''
      cp ${file.path} $out/${lib.escapeShellArg file.name}
    '') (tagEntityFiles ++ monitorFiles)}
  '';
in
{
  assertions = [
    {
      assertion = lib.all (
        service:
        let
          cfg = service.monitoring or { };
        in
        !(cfg.enable or false) || (cfg ? tag && knownTags ? ${cfg.tag})
      ) (lib.attrValues constants.services);
      message = ''
        Every enabled monitoring block must set tag to one of:
        ${lib.concatStringsSep ", " (map (t: ''"${t}"'') (lib.attrNames knownTags))}
      '';
    }
    {
      assertion = lib.all (
        name:
        let
          service = monitoredServices.${name};
          cfg = service.monitoring;
          monitorType = cfg.type or (defaultType service);
        in
        monitorType != "http" || (cfg ? url) || (service ? subdomain)
      ) (lib.attrNames monitoredServices);
      message = "HTTP monitors need a subdomain or monitoring.url.";
    }
    {
      assertion = lib.all (
        name:
        let
          service = monitoredServices.${name};
          cfg = service.monitoring;
          monitorType = cfg.type or (defaultType service);
        in
        monitorType != "port" || (cfg ? port) || (service ? port)
      ) (lib.attrNames monitoredServices);
      message = "Port monitors need service.port or monitoring.port.";
    }
  ];

  homelab.oci-containers.uptime-kuma = {
    image = "ghcr.io/louislam/uptime-kuma:2@sha256:20abea8c48a163cf0a7a5d5936ab418e4b742d908704e1f58f6c06e56a9c6b67";
    volumes = [
      "${constants.users.sandro.home}/uptime-kuma:/app/data"
    ];
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.uptimeKuma.ip}"
    ];
  };

  homelab.oci-containers.autokuma = {
    image = "ghcr.io/bigboot/autokuma:latest@sha256:8acbd3ad3ec8cb6c066aa0ee541154921283ec78159015937128541921c47974";
    environment = {
      AUTOKUMA__KUMA__URL = "http://${constants.services.uptimeKuma.ip}:${toString constants.services.uptimeKuma.port}";
      AUTOKUMA__STATIC_MONITORS = "/monitors";
      AUTOKUMA__DOCKER__ENABLED = "false";
      AUTOKUMA__FILES__ENABLED = "true";
      AUTOKUMA__ON_DELETE = "delete";
      AUTOKUMA__TAG_NAME = "AutoKuma";
      AUTOKUMA__TAG_COLOR = "#42C0FB";
    };
    environmentFiles = [
      config.sops.secrets.autokuma-env.path
    ];
    volumes = [
      "${constants.users.sandro.home}/autokuma:/data"
      "${staticMonitors}:/monitors:ro"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.autokuma.ip}"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${constants.users.sandro.home}/autokuma 0755 ${constants.users.sandro.name} users -"
  ];

  systemd.services.podman-uptime-kuma = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "nas-fetch-uptime-kuma.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.podman-autokuma = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "podman-uptime-kuma.service"
      "sops-nix.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
    requires = [ "podman-uptime-kuma.service" ];
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "uptime-kuma";
        nfsMount = constants.mountPoints.configurations.path;
        source = "uptime-kuma";
        target = "${constants.users.sandro.home}/uptime-kuma";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "uptime-kuma";
        source = "${constants.users.sandro.home}/uptime-kuma";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "uptime-kuma";
        schedule = "daily";
      }
    ];
  };
}
