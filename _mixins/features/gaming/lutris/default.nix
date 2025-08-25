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
    file = {
      # Copy the file to make it writeable.
      "${config.xdg.dataHome}/lutris/system_source.yml" = {
        source = packages.lutris-config + "/etc/lutris/system.yml";
        onChange = ''cat ${config.xdg.dataHome}/lutris/system_source.yml > ${config.xdg.dataHome}/lutris/system.yml'';
      };
    };
    # packages = with pkgs; [
    #   (config.lib.nixGL.wrap lutris)
    # ];
  };
  # todo Installing Lutris this way breaks everything on the Steam Deck.
  # It seems to work okay otherwise, but the Ludusavi configuration isn't kept.
  programs.lutris = {
    enable = true;
    extraPackages = with pkgs; [
      mangohud
      winetricks
      (config.lib.nixGL.wrap gamescope)
      gamemode
      umu-launcher
    ];
    protonPackages = with pkgs; [ proton-ge-bin ];
    package = config.lib.nixGL.wrap pkgs.lutris;
    runners = {
      scummvm.package = config.lib.nixGL.wrap pkgs.scummvm;
    };
    steamPackage =
      if hostname == "steamdeck" then
        (pkgs.runCommandLocal "empty" { } "mkdir $out")
      else
        (config.lib.nixGL.wrap pkgs.steam);
    winePackages = with pkgs; [ wineWow64Packages.full ];
  };
}
