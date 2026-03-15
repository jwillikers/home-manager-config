{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-steam-deck-config";
  version = "0-unstable-2026-03-14";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-steam-deck-config";
    rev = "6c22816cdb378c64f7906154aa7aa5b5cd5b7009";
    hash = "sha256-mMEvQ8klE/05BSmXpIzHL7+g1vHLUqxE/uP8UPZf7rw=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
