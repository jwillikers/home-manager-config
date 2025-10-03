{
  config,
  hostname,
  lib,
  packages,
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
  home = {
    activation = {
      inputplumber =
        lib.hm.dag.entryAfter
          [
            "escalationProgram"
            "writeBoundary"
          ]
          ''
            run "$escalation_program" mkdir --parents /etc/inputplumber/{devices,profiles}.d
            run "$escalation_program" cp --recursive ${packages.inputplumber-profiles}/etc/inputplumber/devices.d/* /etc/inputplumber/devices.d/
            run "$escalation_program" cp --recursive ${packages.inputplumber-profiles}/etc/inputplumber/profiles.d/* /etc/inputplumber/profiles.d/
            run "$escalation_program" systemctl enable inputplumber.service inputplumber-suspend.service
            run "$escalation_program" systemctl restart inputplumber.service
          '';
    };
    file = {
      "${config.xdg.configHome}/lutris/scripts/lutris-inputplumber-pre-launch.sh".source =
        packages.inputplumber-profiles + "/etc/lutris/scripts/lutris-inputplumber-pre-launch.sh";
      "${config.xdg.configHome}/lutris/scripts/lutris-inputplumber-post-exit.sh".source =
        packages.inputplumber-profiles + "/etc/lutris/scripts/lutris-inputplumber-post-exit.sh";
    };
    packages = with pkgs; [
      inputplumber
    ];
  };
}
