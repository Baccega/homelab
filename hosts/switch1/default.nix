{ pkgs, constants }:

let
  ip = constants.networkGear.switch1.ip;
  configPath = "hosts/switch1/config.rsc";
  commonSecretsPath = "secrets/switch1-secrets.json";
  remotePath = "flash/config.rsc";

  export = pkgs.writeShellApplication {
    name = "switch1-export";
    runtimeInputs = with pkgs; [ openssh coreutils gnused jq sops ];
    text = ''
      set -euo pipefail

      if [ -z "''${REPO_ROOT:-}" ]; then
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      fi

      switch1_admin="$(
        sops --decrypt "$REPO_ROOT/${commonSecretsPath}" \
          | jq -r '."switch1-admin"'
      )"
      if [ -z "$switch1_admin" ] || [ "$switch1_admin" = "null" ]; then
        echo "ERROR: missing switch1-admin in ${commonSecretsPath}."
        exit 1
      fi

      out="$REPO_ROOT/${configPath}"
      mkdir -p "$(dirname "$out")"

      echo "Exporting live config from $switch1_admin@${ip} -> $out"
      ssh -o StrictHostKeyChecking=accept-new "$switch1_admin@${ip}" \
        '/export show-sensitive' \
        | sed '/^[^#]/,$!d' \
        > "$out.tmp"
      mv "$out.tmp" "$out"

      echo "Done. Review with: git diff -- ${configPath}"
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "switch1-deploy";
    runtimeInputs = with pkgs; [ openssh coreutils diffutils gnused jq sops ];
    text = ''
      set -euo pipefail

      if [ -z "''${REPO_ROOT:-}" ]; then
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      fi

      switch1_admin="$(
        sops --decrypt "$REPO_ROOT/${commonSecretsPath}" \
          | jq -r '."switch1-admin"'
      )"
      if [ -z "$switch1_admin" ] || [ "$switch1_admin" = "null" ]; then
        echo "ERROR: missing switch1-admin in ${commonSecretsPath}."
        exit 1
      fi

      local_cfg="$REPO_ROOT/${configPath}"
      if [ ! -s "$local_cfg" ]; then
        echo "ERROR: $local_cfg is missing or empty."
        echo "Run 'nix run .#switch1-export' first to populate it from the live device."
        exit 1
      fi

      echo "Fetching live config from $switch1_admin@${ip} for diff..."
      live=$(mktemp)
      trap 'rm -f "$live"' EXIT
      ssh -o StrictHostKeyChecking=accept-new "$switch1_admin@${ip}" \
        '/export show-sensitive' \
        | sed '/^[^#]/,$!d' \
        > "$live"

      echo
      echo "=== diff (live -> local) ==="
      if diff -u "$live" "$local_cfg"; then
        echo "No changes. Nothing to deploy."
        exit 0
      fi
      echo "=== end diff ==="
      echo

      echo "About to RESET ${ip} and re-import the local config."
      echo "This will cause a brief outage (~30-60s) while the switch reboots."
      read -rp "Type 'yes' to continue: " ans
      if [ "$ans" != "yes" ]; then
        echo "Aborted."
        exit 1
      fi

      echo "Uploading $local_cfg -> $switch1_admin@${ip}:${remotePath}"
      scp -O -o StrictHostKeyChecking=accept-new \
        "$local_cfg" "$switch1_admin@${ip}:${remotePath}"

      echo "Triggering reset + re-import..."
      ssh -o StrictHostKeyChecking=accept-new "$switch1_admin@${ip}" \
        '/system/reset-configuration no-defaults=yes skip-backup=yes run-after-reset=${remotePath}' \
        || true

      echo "Done. The switch is rebooting; give it ~60s before retrying ssh."
    '';
  };
in
{
  inherit export deploy;
}
