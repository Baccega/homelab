{
    ...
}:
{
    imports = [
        ../../../modules/common/sops.nix
    ];

    sops.secrets = {
        laika-docker-env = {
            sopsFile = ../../../secrets/laika-secrets.json;
        };
    };
}
