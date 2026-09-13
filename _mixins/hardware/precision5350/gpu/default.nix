_: {
  # NVIDIA requires using the --impure flag.
  targets.genericLinux = {
    gpu.nvidia = {
      enable = true;
      version = "580.178.04";
      sha256 = "sha256-WXWobuRb/8tib1GuM9EWmxCBhqLqR61lHnLxP6S21vk=";
    };
    nixGL.prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    #  offloadWrapper = "nvidiaPrime";
  };
}
