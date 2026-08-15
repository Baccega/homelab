{ config, lib, ... }:
let
  cfg = config.homelab.oci-containers;
in
{
  options.homelab.oci-containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = { };
    description = "OCI containers with homelab-wide security defaults.";
  };

  config.virtualisation.oci-containers.containers = lib.mapAttrs (
    _name: container:
    container
    // {
      extraOptions = [
        "--security-opt=no-new-privileges"
      ]
      ++ (container.extraOptions or [ ]);
    }
  ) cfg;
}
