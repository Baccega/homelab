# Evaluate with: nix eval --impure --expr 'import ./tests/immich.nix'
let
  flake = builtins.getFlake (toString ../.);
  constants = import ../constants.nix;
  max = flake.nixosConfigurations.max.config;
  nemo = flake.nixosConfigurations.nemo.config;
  containers = max.virtualisation.oci-containers.containers;
  service = constants.services.immich;
  hostname = "${service.subdomain}.${constants.network.publicDomain}";
  immichContainers = [
    containers.immich-server
    containers.immich-postgres
    containers.immich-valkey
    containers.immich-machine-learning
  ];
  backup = builtins.head (builtins.filter (job: job.name == "immich") max.backup.jobs);
in
assert builtins.hasAttr "immich-server" containers;
assert builtins.elem "${constants.hosts.max.networkStack.name}:ip=${service.ip}" containers.immich-server.networks;
assert containers.immich-postgres.networks == [ "immich-private" ];
assert containers.immich-valkey.networks == [ "immich-private" ];
assert containers.immich-machine-learning.networks == [ "immich-private" ];
assert builtins.all (container: container.ports == [ ]) immichContainers;
assert builtins.all (container: builtins.match ".*@sha256:[0-9a-f]{64}" container.image != null)
  immichContainers;
assert builtins.elem "/${hostname}/${constants.hosts.nemo.ip}" nemo.services.dnsmasq.settings.address;
assert flake.inputs.nixpkgs.lib.hasInfix (builtins.concatStringsSep "\n" [
  "http://${hostname}, ${hostname} {"
  "  import cloudflare_tls"
  "  reverse_proxy ${service.ip}:${toString service.port} {"
  "    header_up -CF-Access-Client-Id"
  "    header_up -CF-Access-Client-Secret"
  "    header_up -Cf-Access-Jwt-Assertion"
  "  }"
  "}"
]) nemo.sops.templates.Caddyfile.content;
assert backup.source == "/var/lib/immich/backup";
assert backup.preBackupScript != null;
assert max.systemd.services.backup-immich.unitConfig.AssertPathIsMountPoint == backup.nfsMount;
"Immich Max service, Nemo ingress and NAS backup checks passed"
