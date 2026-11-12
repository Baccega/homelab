# Native headless T3. See ../T3-CODE.md before deployment or migration.
{ pkgs, ... }:
let
  home = "/var/lib/t3-code";
  tailnetIp = (import ../../../constants.nix).hosts.bolt.tailscaleIp;
  t3 = pkgs.t3code.override {
    enableCodex = false;
    enableClaude = false;
    enableCursor = false; 
    enableCursorCli = true;
  };
  # Nixpkgs exports cursor-agent; Cursor documents agent login/status.
  cursorAgent = pkgs.writeShellScriptBin "agent" ''
    export AGENT_CLI_CREDENTIAL_STORE=file
    exec ${pkgs.cursor-cli}/bin/cursor-agent "$@"
  '';
  tools = with pkgs; [
    t3 cursor-cli cursorAgent codex nodejs_24 corepack git gh openssh
    ripgrep jq rsync curl cacert
    bashInteractive coreutils findutils util-linux nix lsof
  ];
in
{
  users.groups.t3-code = { };
  users.users.t3-code = {
    isSystemUser = true;
    group = "t3-code";
    home = home;
    createHome = true;
    homeMode = "0700";
    shell = pkgs.bashInteractive;
  };

  environment.systemPackages = tools;
  # T3 downloads a sandboxed Chrome build on first browser use. Its ELF loader
  # and runtime libraries must exist on NixOS. Do not disable Chrome's sandbox.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib glib nss nspr dbus atk at-spi2-atk cups expat
      libdrm libxkbcommon libgbm alsa-lib pango cairo
      libX11 libXcomposite libXdamage libXext libXfixes libXrandr libxcb
    ];
  };
  fonts.packages = [ pkgs.dejavu_fonts ];

  systemd.tmpfiles.rules = [
    "d ${home} 0700 t3-code t3-code -"
    "d ${home}/projects 0700 t3-code t3-code -"
    "d ${home}/wiki-outbox 0700 t3-code t3-code -"
    "f ${home}/server.log 0600 t3-code t3-code -"
  ];
  # No wildcard or LAN listener and no global firewall opening.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3773 ];

  systemd.services.t3-code = {
    description = "T3 Code personal projects (tailnet only)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    after = [ "network-online.target" "tailscaled.service" ];
    path = tools;
    environment = {
      HOME = home;
      T3CODE_HOME = "${home}/.t3";
      # Supported by this pinned CLI; no desktop keychain/DBus login needed.
      AGENT_CLI_CREDENTIAL_STORE = "file";
      # Also use this HOME for provider auth and caches; no Pongo credentials.
      XDG_CONFIG_HOME = "${home}/.config";
      XDG_CACHE_HOME = "${home}/.cache";
      XDG_STATE_HOME = "${home}/.local/state";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      User = "t3-code";
      Group = "t3-code";
      StateDirectory = "t3-code";
      StateDirectoryMode = "0700";
      WorkingDirectory = "${home}/projects";
      ExecStart = "${t3}/bin/t3 serve --host ${tailnetIp} --port 3773 --base-dir ${home}/.t3";
      Restart = "always";
      RestartSec = "10s";
      TimeoutStopSec = "60s";
      KillMode = "control-group";
      UMask = "0077";
      # Headless startup prints a pairing credential. Keep it out of journal.
      StandardOutput = "append:${home}/server.log";
      StandardError = "append:${home}/server.log";
      ProtectHome = true;
      ProtectSystem = "full";
      # Leave user namespaces available for provider and Chrome sandboxes.
    };
  };
  services.logrotate.settings.t3-code = {
    files = [ "${home}/server.log" ];
    frequency = "daily";
    rotate = 7;
    size = "10M";
    copytruncate = true;
    compress = true;
    su = "t3-code t3-code";
  };
}
