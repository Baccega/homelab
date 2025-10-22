{
  config,
  ...
}:
{
    sops = {
        defaultSopsFile = ../../secrets/secrets.json;
        defaultSopsFormat = "json";

        age = {
            sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
        };
        secrets = {
            laika-docker-env = {};
            max-docker-env = {};
            root-password = {};
            sandro-password = {};
            "wireless.env" = {};
            qbittorrent-password = {
                owner = "sandro";
            };
            sabnzbd-username = {
                owner = "sandro";
            };
            sabnzbd-password = {
                owner = "sandro";
            };
            sabnzbd-api-key = {
                owner = "sandro";
            };
            sabnzbd-nzb-key = {
                owner = "sandro";
            };
            usenet-host = {
                owner = "sandro";
            };
            usenet-username = {
                owner = "sandro";
            };
            usenet-password = {
                owner = "sandro";
            };
            # github_token = {
            #     sopsFile = ../../secrets/max-secrets.json;
            #     sopsFile = ../../secrets/github-secrets.json;
            # };
        };
    };

}