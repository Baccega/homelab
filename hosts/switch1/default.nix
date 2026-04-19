{ pkgs, constants }:

let
  ip = constants.networkGear.switch1.ip;
  sshUser = "admin";
  configPath = "hosts/switch1/config.rsc";
  remotePath = "flash/config.rsc";

  export = pkgs.writeShellApplication {
    name = "switch1-export";
    runtimeInputs = with pkgs; [ openssh coreutils gnused ];
    text = ''
      set -euo pipefail

      if [ -z "''${REPO_ROOT:-}" ]; then
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      fi

      out="$REPO_ROOT/${configPath}"
      mkdir -p "$(dirname "$out")"

      echo "Exporting live config from ${sshUser}@${ip} -> $out"
      ssh -o StrictHostKeyChecking=accept-new "${sshUser}@${ip}" \
        '/export show-sensitive' \
        | sed '1{/^# .* by RouterBOARD/d;}' \
        > "$out.tmp"
      mv "$out.tmp" "$out"

      echo "Done. Review with: git diff -- ${configPath}"
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "switch1-deploy";
    runtimeInputs = with pkgs; [ openssh coreutils diffutils gnused ];
    text = ''
      set -euo pipefail

      if [ -z "''${REPO_ROOT:-}" ]; then
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      fi

      local_cfg="$REPO_ROOT/${configPath}"
      if [ ! -s "$local_cfg" ]; then
        echo "ERROR: $local_cfg is missing or empty."
        echo "Run 'nix run .#switch1-export' first to populate it from the live device."
        exit 1
      fi

      echo "Fetching live config from ${sshUser}@${ip} for diff..."
      live=$(mktemp)
      trap 'rm -f "$live"' EXIT
      ssh -o StrictHostKeyChecking=accept-new "${sshUser}@${ip}" \
        '/export show-sensitive' \
        | sed '1{/^# .* by RouterBOARD/d;}' \
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

      echo "Uploading $local_cfg -> ${sshUser}@${ip}:${remotePath}"
      scp -O -o StrictHostKeyChecking=accept-new \
        "$local_cfg" "${sshUser}@${ip}:${remotePath}"

      echo "Triggering reset + re-import..."
      ssh -o StrictHostKeyChecking=accept-new "${sshUser}@${ip}" \
        '/system/reset-configuration no-defaults=yes skip-backup=yes run-after-reset=${remotePath}' \
        || true

      echo "Done. The switch is rebooting; give it ~60s before retrying ssh."
    '';
  };
in
{
  inherit export deploy;
}
