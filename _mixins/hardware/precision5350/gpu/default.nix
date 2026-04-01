_: {
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.142";
      sha256 = "sha256-IJFfzz/+icNVDPk7YKBKKFRTFQ2S4kaOGRGkNiBEdWM=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
