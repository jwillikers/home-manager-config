{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-steam-deck-config";
  version = "0-unstable-2025-09-29";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-steam-deck-config";
    rev = "e473a55a1cdaa096fd8637718f805073b81969ee";
    hash = "sha256-unP/ihQbgx3ycoRVQW5/YlGqhXhZ1eOSGIPQBH0Tt1c=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
