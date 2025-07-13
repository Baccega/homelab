{
  pkgs,
  config,
  ...
}:
{
    networking.networkmanager = {
        enable = true;
        ensureProfiles = {
            environmentFiles = [ config.sops.secrets."wireless.env".path ];
            profiles = {
                home-wifi = {
                    connection.id = "home-wifi";
                    connection.type = "wifi";
                    wifi.ssid = "$WIFI_SSID";
                    wifi-security = {
                        auth-alg = "open";
                        key-mgmt = "wpa-psk";
                        psk = "$WIFI_PASSWORD";
                    };
                };
            };
        };
    };
}