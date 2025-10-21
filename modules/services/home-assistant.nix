{
  pkgs,
  config,
  ...
}:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Vienna";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [ 
        "--network=host" 
        # "--device=/dev/ttyACM0:/dev/ttyACM0" 
      ];
    };
  };
  networking.firewall.allowedTCPPortRanges = 
    [{
      from = 100;
      to = 65535;
    }];
  networking.firewall.allowedUDPPortRanges = 
    [{
      from = 100;
      to = 65535;
    }];
#   services.home-assistant.config = {
#     "automation manual" = [
#       {
#         alias = "Shutdown Servers on Power Outage";
#         trigger = {
#             platform = "state";
#             entity_id = "switch.homelab_socket";
#             to = "off";
#             for = {
#                 seconds = 20;
#             };
#         };
#         action = {
#             type = "turn_on";
#             entity_id = "switch.homelab_socket";
#             domain = "switch";
#         };
#       }
#     ];
#     "automation ui" = "!include automations.yaml";
#  };


}

# alias: Shutdown Servers on Power Outage
# trigger:
#   - platform: state
#     entity_id: binary_sensor.power_mains_status
#     to: 'off'
#     for:
#       minutes: 10  # Time to wait before shutdown
# condition: []
# action:
#   - service: notify.mobile_app_yourphone  # Optional: Notify yourself
#     data:
#       message: "Power outage for 10 minutes. Initiating server shutdown."
#   - service: shell_command.shutdown_servers  # Define this in configuration.yaml
# mode: single