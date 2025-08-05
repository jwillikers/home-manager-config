{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-steam-deck-config";
  version = "0-unstable-2025-08-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-steam-deck-config";
    rev = "fd3f117173090002febe51f6dbeff72a2dd8c3fb";
    hash = "sha256-tECSng6+eZKGv8VV0tmTDa322gODPmp+7GG9Lx9Ubgo=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
