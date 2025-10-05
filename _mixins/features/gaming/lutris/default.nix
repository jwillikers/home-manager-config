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
      "${config.xdg.configHome}/lutris/system_source.yml" = {
        text = builtins.replaceStrings [ "/home/jordan/.config" ] [ config.xdg.configHome ] (
          builtins.readFile (packages.lutris-config + "/etc/lutris/system.yml")
        );
        onChange = ''cat ${config.xdg.configHome}/lutris/system_source.yml > ${config.xdg.configHome}/lutris/system.yml'';
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
      (config.lib.nixGL.wrap flatpak)
      (config.lib.nixGL.wrap gamemode)
      (config.lib.nixGL.wrap gamescope)
      inputplumber
      (config.lib.nixGL.wrap mangohud)
      (config.lib.nixGL.wrap umu-launcher)
      (config.lib.nixGL.wrap winetricks)
    ];
    protonPackages = with pkgs; [ proton-ge-bin ];
    package = config.lib.nixGL.wrap pkgs.lutris;
    runners = {
      scummvm.package = config.lib.nixGL.wrap pkgs.scummvm;
    };
    steamPackage = config.lib.nixGL.wrap pkgs.steam;
    winePackages = with pkgs; [ wineWow64Packages.full ];
  };
}
