# Virtual audio sink for headless game streaming (PipeWire null sink).
# Sunshine captures the monitor of this sink for Moonlight.
{
  ...
}:
let
  constants = import ../../../constants.nix;
  sinkName = "sunshine-virtual";
in
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."90-sunshine-null-sink" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = sinkName;
            "node.description" = "Sunshine Virtual Sink";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
            "monitor.channel-volumes" = true;
          };
        }
      ];
    };
  };

  users.users.${constants.users.sandro.name}.extraGroups = [ "audio" ];
}
