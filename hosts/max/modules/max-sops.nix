{
    ...
}:
{
    imports = [
        ../../../modules/common/sops.nix
    ];

    sops.secrets = {
        max-docker-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        code-server-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
    };
}
