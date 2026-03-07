{
    ...
}:
{
    imports = [
        ../../../modules/common/sops.nix
    ];

    sops.secrets = {
        nemo-docker-env = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        cloudflared-token = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        cloudflare-api-token = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        balto-lan-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        laika-wlp2s0-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        max-eno1-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        hachiko-lan1-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        switch1-bridge1-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        ap1-lan-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        smart-switch-1-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        smart-switch-2-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        smart-switch-3-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
        smart-switch-4-interface = {
            sopsFile = ../../../secrets/nemo-secrets.json;
        };
    };
}
