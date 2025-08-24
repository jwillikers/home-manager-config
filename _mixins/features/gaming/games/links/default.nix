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

    ## Broken Age
    "v '${config.xdg.dataHome}/doublefine/BrokenAge/saves' 0750 ${username} ${username} - -"
    "L+ '${config.xdg.dataHome}/Steam/steamapps/common/Broken\ Age/saves' - - - - '${config.xdg.dataHome}/doublefine/BrokenAge/saves'"
    ## Dome Keeper
    "v '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper' 0750 ${username} ${username} - -"
    "L+ '${config.home.homeDirectory}/Games/gog/dome-keeper/drive_c/users/${username}/AppData/Roaming/Godot/app_userdata/Dome Keeper' - - - - '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper'"
    ## Golf With Your Friends
    "v '${config.xdg.configHome}/Team17 Digital Ltd/Golf With Your Friends' 0750 ${username} ${username} - -"
    "L+ '${config.home.homeDirectory}/Games/gog/kingdom-two-crowns/drive_c/users/${username}/AppData/LocalLow/Team17 Digital Ltd/Golf With Your Friends' - - - - '${config.xdg.configHome}/Team17 Digital Ltd/Golf With Your Friends'"
    ## Kingdom Two Crowns
    "v ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release 0750 ${username} ${username} - -"
    "L+ ${config.home.homeDirectory}/Games/gog/kingdom-two-crowns/drive_c/users/${username}/AppData/LocalLow/noio/KingdomTwoCrowns/Release - - - - ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release"
    ## Thief: Definitive Edition
    "v '${config.home.homeDirectory}/My Games/Thief' 0750 ${username} ${username} - -"
    # Manually do this one since it contains my Steam User ID:
    # Symlink '~/.local/share/Steam/userdata/*/239160/remote' to '~/My Games/Thief'
    ## Toasterball
    "v '${config.home.homeDirectory}/Games/gog/toasterball/drive_c/users/deck/AppData/LocalLow/Les Crafteurs/Toasterball' 0750 ${username} ${username} - -"
    "L+ '${config.xdg.dataHome}/Steam/steamapps/compatdata/1142810/pfx/drive_c/users/steamuser/AppData/LocalLow/Les Crafteurs/Toasterball' - - - - '${config.home.homeDirectory}/Games/gog/toasterball/drive_c/users/deck/AppData/LocalLow/Les Crafteurs/Toasterball'"
  ];
}
