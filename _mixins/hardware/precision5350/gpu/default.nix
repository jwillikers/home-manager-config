_:
{
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.126.09";
      sha256 = "sha256-TKxT5I+K3/Zh1HyHiO0kBZokjJ/YCYzq/QiKSYmG7CY=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
