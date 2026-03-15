{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Rule for Stretchly breaks timer.
  home = {
    file = {
      "${config.xdg.configHome}/kwinrulesrc_source" = {
        source = ./kwinrulesrc;
        onChange = ''
          cat ${config.xdg.configHome}/kwinrulesrc_source > ${config.xdg.configHome}/kwinrulesrc
          ${lib.getBin pkgs.kdePackages.qttools}/bin/qdbus org.kde.KWin /KWin reconfigure
        '';
      };
    };
  };
}
