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
        max-beszel-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        code-server-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        paperless-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        postgres-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        redis-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
        ai-stack-env = {
            sopsFile = ../../../secrets/max-secrets.json;
        };
    };
}
