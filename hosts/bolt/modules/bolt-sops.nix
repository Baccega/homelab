{
  config,
  ...
}:
{
  imports = [
    ../../../modules/common/sops.nix
  ];

  sops.secrets = {
    backup-healthcheck-url = {
      sopsFile = ../../../secrets/bolt-secrets.json;
    };
  };

  backup.healthcheckUrlFile = config.sops.secrets.backup-healthcheck-url.path;
}
