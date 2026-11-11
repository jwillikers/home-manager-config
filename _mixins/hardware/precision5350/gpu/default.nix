_: {
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.196.07";
      sha256 = "sha256-CqsFGNtTz3PEEtx/MrvIUMqV6DnYkj0N5L/0LByRac4=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
