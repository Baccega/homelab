# CouchDB on Max, used as the Self-hosted LiveSync backend for Obsidian.
# There is no separate "LiveSync server": the plugin talks to CouchDB over HTTPS
# through Nemo's Caddy + Cloudflare Tunnel. Do not put Cloudflare Access in
# front of this hostname (the plugin uses CouchDB basic auth). In the plugin,
# enable "Use Request API" so Cloudflare's 100s proxy timeout does not 524
# longpoll requests.
{
  config,
  pkgs,
  ...
}:
let
  constants = import ../../../constants.nix;

  dataDir = "${constants.users.sandro.home}/couchdb/data";
  etcDir = "${constants.users.sandro.home}/couchdb/etc";
  localdDir = "${constants.users.sandro.home}/couchdb/local.d";

  couchdbUrl = "http://127.0.0.1:${toString constants.services.couchdb.port}";

  # Official LiveSync CouchDB config. require_valid_user is applied by
  # couchdb-init after first-run cluster setup, not here: CouchDB must start
  # without auth lockdown so it can create _users / _replicator.
  livesyncIni = pkgs.writeText "livesync.ini" ''
    [couchdb]
    max_document_size = 50000000

    [chttpd]
    bind_address = 0.0.0.0
    port = ${toString constants.services.couchdb.port}
    max_http_request_size = 4294967296

    [httpd]
    WWW-Authenticate = Basic realm="couchdb"

    [cors]
    credentials = true
    origins = app://obsidian.md,capacitor://localhost,http://localhost

    [log]
    level = warning
  '';

  # Idempotent port of vrtmrz/obsidian-livesync docker/scripts/couchdb-init.sh.
  # Runs inside the container (ipvlan: the host cannot reach the container IP).
  initScript = pkgs.writeText "couchdb-init.sh" ''
    #!/bin/sh
    set -e

    hostname="${couchdbUrl}"
    username="''${COUCHDB_USER:?COUCHDB_USER is required}"
    password="''${COUCHDB_PASSWORD:?COUCHDB_PASSWORD is required}"
    node="_local"
    db="''${COUCHDB_DATABASE:-obsidiannotes}"

    # Authenticated wait: once require_valid_user is set, /_up answers 401 to
    # anonymous requests, so an unauthenticated probe would never succeed on
    # any start after the first one. The admin exists from the first boot
    # (the entrypoint writes it into local.d/docker.ini from the env vars).
    echo "==> Waiting for CouchDB at ''${hostname} ..."
    until curl -sf --user "''${username}:''${password}" "''${hostname}/_up" 2>/dev/null | grep -q '"status":"ok"'; do
      sleep 2
    done

    echo "==> CouchDB is up. Initializing..."

    cluster_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "''${hostname}/_cluster_setup" \
      -H "Content-Type: application/json" \
      -d "{\"action\":\"enable_single_node\",\"username\":\"''${username}\",\"password\":\"''${password}\",\"bind_address\":\"0.0.0.0\",\"port\":${toString constants.services.couchdb.port},\"singlenode\":true}" \
      --user "''${username}:''${password}")
    case "''${cluster_code}" in
      200|201) echo "[OK] cluster_setup" ;;
      400|406) echo "[OK] cluster_setup already done (''${cluster_code})" ;;
      *) echo "[WARN] cluster_setup returned ''${cluster_code}" ;;
    esac

    put_config() {
      section="$1"
      key="$2"
      value="$3"
      curl -sf -X PUT "''${hostname}/_node/''${node}/_config/''${section}/''${key}" \
        -H "Content-Type: application/json" \
        -d "''${value}" \
        --user "''${username}:''${password}" >/dev/null
      echo "[OK] ''${section}/''${key}"
    }

    put_config chttpd require_valid_user '"true"'
    put_config chttpd_auth require_valid_user '"true"'
    put_config httpd WWW-Authenticate '"Basic realm=\"couchdb\""'
    put_config httpd enable_cors '"true"'
    put_config chttpd enable_cors '"true"'
    put_config chttpd max_http_request_size '"4294967296"'
    put_config couchdb max_document_size '"50000000"'
    put_config cors credentials '"true"'
    put_config cors origins '"app://obsidian.md,capacitor://localhost,http://localhost"'
    put_config cors headers '"accept, authorization, content-type, origin, referer"'
    put_config cors methods '"GET,PUT,POST,HEAD,DELETE"'
    put_config cors max_age '"3600"'

    status=$(curl -s -o /dev/null -w "%{http_code}" --user "''${username}:''${password}" "''${hostname}/''${db}")
    if [ "$status" = "200" ]; then
      echo "[OK] database ''${db} already exists"
    else
      curl -sf -X PUT "''${hostname}/''${db}" --user "''${username}:''${password}" >/dev/null
      echo "[OK] database ''${db} created"
    fi

    echo "==> CouchDB initialization complete"
  '';
in
{
  homelab.oci-containers.couchdb = {
    image = "docker.io/library/couchdb:3@sha256:9ea24cbd76522fe845d1c32c7fd1dcfc8a3ba73dcc4817d62f8a7f7f1dfaffe3";
    environment = {
      COUCHDB_USER = "obsidian";
      COUCHDB_DATABASE = "obsidiannotes";
    };
    environmentFiles = [
      config.sops.secrets.max-docker-env.path
      config.sops.secrets.couchdb-env.path
    ];
    # Do not mark local.ini :ro: the official entrypoint chmod's /opt/couchdb/etc
    # at startup and exits with EPERM on a read-only bind mount.
    # Do not set --user: the entrypoint starts as root to write docker.ini, then
    # drops to uid 5984.
    volumes = [
      "${dataDir}:/opt/couchdb/data"
      "${etcDir}/local.ini:/opt/couchdb/etc/local.ini"
      "${localdDir}:/opt/couchdb/etc/local.d"
      "${initScript}:/usr/local/bin/couchdb-init.sh"
    ];
    networks = [ constants.hosts.max.networkStack.name ];
    extraOptions = [
      "--ip=${constants.services.couchdb.ip}"
    ];
  };

  systemd.services.couchdb-prepare = {
    description = "Write CouchDB LiveSync local.ini";
    requiredBy = [ "podman-couchdb.service" ];
    before = [ "podman-couchdb.service" ];
    # Pull in the NAS restore so it cannot land after the directories exist
    # (nas-fetch skips a target that is already present).
    wants = [ "nas-fetch-couchdb.service" ];
    after = [ "nas-fetch-couchdb.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "couchdb-prepare" ''
        set -euo pipefail
        mkdir -p "${dataDir}" "${etcDir}" "${localdDir}"
        if [ -d "${etcDir}/local.ini" ]; then
          rm -rf "${etcDir}/local.ini"
        fi
        cp ${livesyncIni} "${etcDir}/local.ini"
        chmod 644 "${etcDir}/local.ini"
      '';
    };
  };

  systemd.services.podman-couchdb = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-nix.service"
      "nas-fetch-couchdb.service"
      "couchdb-prepare.service"
      "create-podman-network-${constants.hosts.max.networkStack.name}.service"
    ];
  };

  systemd.services.couchdb-init = {
    description = "Apply LiveSync settings to CouchDB";
    wantedBy = [ "podman-couchdb.service" ];
    bindsTo = [ "podman-couchdb.service" ];
    after = [
      "podman-couchdb.service"
      "sops-nix.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "5min";
      # The script waits for CouchDB itself; this loop only covers the window
      # where the container is not yet accepting exec.
      ExecStart = pkgs.writeShellScript "couchdb-init" ''
        set -euo pipefail
        for _ in $(seq 1 30); do
          if ${pkgs.podman}/bin/podman exec couchdb sh /usr/local/bin/couchdb-init.sh; then
            exit 0
          fi
          sleep 5
        done
        echo "CouchDB initialization did not succeed" >&2
        exit 1
      '';
    };
  };

  services.nas-fetch = {
    enable = true;
    syncPaths = [
      {
        name = "couchdb";
        nfsMount = constants.mountPoints.configurations.path;
        source = "couchdb";
        target = "${constants.users.sandro.home}/couchdb";
        user = constants.users.alfred.uid;
        group = constants.groups.users;
      }
    ];
  };

  backup = {
    enable = true;
    jobs = [
      {
        name = "couchdb";
        source = "${constants.users.sandro.home}/couchdb";
        nfsMount = constants.mountPoints.configurations.path;
        destination = "couchdb";
        schedule = "daily";
      }
    ];
  };
}
