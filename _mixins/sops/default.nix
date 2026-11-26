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
      "${hostname}/gog-username" = { };
    };
  };
  # Stay active after decrypting the secrets.
  # Otherwise, every restart of a unit that requires sops-nix runs it again and can hit the start limit.
  # The sops-nix activation script restarts the unit, so secrets are still decrypted again on each switch.
  systemd.user.services.sops-nix.Service.RemainAfterExit = true;
}
