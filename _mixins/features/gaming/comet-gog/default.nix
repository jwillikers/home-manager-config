{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "precision5350"
    "steamdeck"
    "x1-yoga"
  ];
in
lib.mkIf (lib.elem hostname installOn) {
  home.packages = with pkgs; [
    comet-gog
  ];

  systemd.user.services = {
    "comet" = {
      Unit = {
        Description = "Run Comet GOG integration service";
        After = [
          "default.target"
          "sops-nix.service"
        ];
        Requires = [ "sops-nix.service" ];
      };

      Service = {
        Type = "notify";
        ExecStart = pkgs.writeShellApplication {
          # Simple script to obtain GOG username from secrets file and run comet.
          name = "comet.sh";
          runtimeInputs = with pkgs; [
            comet-gog
            systemdMinimal
          ];
          # Requires signing in to GOG in Lutris.
          text = ''
            username=$(<${config.sops.secrets."${hostname}/gog-username".path})
            if [ -n "''${NOTIFY_SOCKET+x}" ]; then
              systemd-notify --ready --status="Running comet with Lutris integration"
            fi
            comet --from-lutris --username "$username"
          '';
        };
        Restart = "always";
        NotifyAccess = "all";
        Slice = "background.slice";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
