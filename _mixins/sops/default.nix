{
  inputs,
  config,
  hostname,
  username,
  ...
}:
let
  sopsFolder = builtins.toString inputs.nix-secrets;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = "${sopsFolder}/users/${username}.yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    secrets = {
      "${hostname}/nextcloud-ludusavi" = {
        # path = "%r/sops-secrets/nextcloud-ludusavi.txt";
      };
    };
  };
}
