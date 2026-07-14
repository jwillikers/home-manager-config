_: {
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.173.02";
      sha256 = "sha256-jY65AB4FqaimY9PV0wT+tk7yhE7hhczf2VJ4aCD0bhs=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
