_:
{
  # NVIDIA requires using the --impure flag.
  nixGL = {
    defaultWrapper = "nvidia";
    installScripts = [
      "nvidia"
      "nvidiaPrime"
    ];
    prime = {
      card = "01:00.0"; # NVIDIA Card
      installScript = "nvidia";
    };
    offloadWrapper = "nvidiaPrime";
  };
}
