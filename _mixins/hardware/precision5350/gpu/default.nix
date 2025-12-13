_: {
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.105.08";
      sha256 = "sha256-2cboGIZy8+t03QTPpp3VhHn6HQFiyMKMjRdiV2MpNHU=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
