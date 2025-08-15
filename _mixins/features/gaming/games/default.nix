{
  config,
  hostname,
  lib,
  username,
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
  systemd.user.tmpfiles.rules = [
    # Symlink game save data between multiple locations.
    ## Kingdom Two Crowns
    "v ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release 0750 ${username} ${username} - -"
    "L+ ${config.home.homeDirectory}/Games/gog/kingdom-two-crowns/drive_c/users/${username}/AppData/LocalLow/noio/KingdomTwoCrowns/Release - - - - ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release"
    ## Dome Keeper
    "v '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper' 0750 ${username} ${username} - -"
    "L+ '${config.home.homeDirectory}/Games/gog/dome-keeper/drive_c/users/${username}/AppData/Roaming/Godot/app_userdata/Dome Keeper' - - - - '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper'"
  ];
}
