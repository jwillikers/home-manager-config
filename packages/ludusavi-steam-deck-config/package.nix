{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-steam-deck-config";
  version = "0-unstable-2025-09-03";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-steam-deck-config";
    rev = "f1d4177c3803e2a01d27fbcdbbf13d2d67a15554";
    hash = "sha256-2PYd4lANTpS/JosbdPiZF3zwIDn93Py9AAqmcEnfHKI=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
