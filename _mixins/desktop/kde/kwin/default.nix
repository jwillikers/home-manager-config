{
  config,
  ...
}:
{
  # Rule for Stretchly breaks timer.
  home = {
    file = {
      "${config.xdg.configHome}/kwinrulesrc_source" = {
        source = ./kwinrulesrc;
        onChange = "cat ${config.xdg.configHome}/kwinrulesrc_source > ${config.xdg.configHome}/kwinrulesrc";
      };
    };
  };
}
