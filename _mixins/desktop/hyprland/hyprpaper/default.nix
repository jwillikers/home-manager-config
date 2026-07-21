_: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      preload = [ "/usr/share/backgrounds/default-dark.jxl" ];
      wallpaper = [
        {
          fit_mode = "cover";
          monitor = "";
          path = "/usr/share/backgrounds/default-dark.jxl";
        }
      ];
    };
  };
}
