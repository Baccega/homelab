{
  config,
  ...
}:
{
    sops = {
        defaultSopsFile = ../../secrets/common-secrets.json;
        defaultSopsFormat = "json";

        age = {
            sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
        };
        secrets = {
            laika-docker-env = {};
            max-docker-env = {};
            nemo-docker-env = {};
            root-password = {};
            sandro-password = {};
            "wireless.env" = {};
            code-server-password = {
                owner = "sandro";
            };
            cloudflared-token = {
                owner = "sandro";
            };
            balto-lan-interface = {
                sopsFile = ../../secrets/nemo-secrets.json;
            };
            laika-wlp2s0-interface = {
                sopsFile = ../../secrets/nemo-secrets.json;
            };
            max-eno1-interface = {
                sopsFile = ../../secrets/nemo-secrets.json;
            };
            hachiko-lan1-interface = {
                sopsFile = ../../secrets/nemo-secrets.json;
            };
            # github_token = {
            #     sopsFile = ../../secrets/max-secrets.json;
            #     sopsFile = ../../secrets/github-secrets.json;
            # };
        };
    };

}