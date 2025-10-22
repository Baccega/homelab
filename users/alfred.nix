{
  ...
}:
let
  constants = import ../constants.nix;
  username = "alfred";
in
{
    users.users.alfred = {
        isSystemUser = true;
        uid = constants.users.alfred;
        group = "users";
        extraGroups = [ "podman" ];
    };
}
