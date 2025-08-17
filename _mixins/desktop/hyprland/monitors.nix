_: {
  precision5350 = {
    # monitor = [
    #   "DP-7, 2560x1440@74.780Hz, 1920x0, 1.5"
    #   "eDP-1, 1920x1080@60.027Hz, 0x0, 1"
    #   # "desc:Lenovo Group Limited LEN L24q-30 U560FBWV, 2560x1440@74.780Hz, 1920x0, 1.5" # DP-7
    #   # "desc:BOE 0x06F1, 1920x1080@60.027Hz, 0x0, 1" # eDP-1
    # ];
    monitorv2 = [

      # First monitor is primary
      {
        # output = "DP-7";
        output = "desc:Lenovo Group Limited LEN L24q-30 U560FBWV";
        # description = "Lenovo Group Limited LEN L24q-30 U560FBWV";
        mode = "2560x1440@74.780Hz";
        # mode = "highres@highrr";
        position = "1920x0";
        scale = 1.5; # todo Is this not having an effect?
      }
      {
        # output = "eDP-1";
        output = "desc:BOE 0x06F1";
        # description = "BOE 0x06F1";
        mode = "1920x1080@60.027Hz";
        # mode = "highres@highrr";
        position = "0x0";
        scale = 1;
      }
      {
        # Catch-all
        output = "";
        mode = "highres@highrr";
        position = "auto";
        scale = 1;
      }
    ];
    workspace = [
      "1, name:1, monitor:DP-7, default:true"
      "2, name:2, monitor:eDP-1, default:true"
    ];
  };
}
