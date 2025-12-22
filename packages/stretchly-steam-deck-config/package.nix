{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-steam-deck-config";
  version = "0-unstable-2025-12-22";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-steam-deck-config";
    rev = "ec12e0f23d12fd1ddf618eafd00aa56737fcb97f";
    hash = "sha256-OtWxLhg98XyUbG55yFZRGiGesgJdW7s7elqfJUZVtPw=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
