{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-steam-deck-config";
  version = "0-unstable-2025-10-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-steam-deck-config";
    rev = "47c6f075aac1bf63c29b332b4c3eda38faf75d45";
    hash = "sha256-66wTwkQGN1Ggf3GxM0ivNzTEXwU4s+32UIgPfbcn8+M=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
