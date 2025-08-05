{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "openssh-client-config";
  version = "0-unstable-2025-07-23";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "openssh-client-config";
    rev = "4f7916efa13d97a730ffce24840fe287358f211b";
    hash = "sha256-CmJOmGwgbmgvY2gcurYRy0pvDNKXdltph8xzU0jEXVA=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/ssh/ssh_config.d ssh/config.d/*
    runHook postInstall
  '';
}
