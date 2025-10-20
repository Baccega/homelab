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
            qbittorrent-password = {};
            sabnzbd-password = {};
            sabnzbd-api-key = {};
        };
    };

}