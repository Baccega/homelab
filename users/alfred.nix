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
        uid = constants.users.alfred.uid;
        group = "users";
        extraGroups = [ "podman" ];
    };
}
