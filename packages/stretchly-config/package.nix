{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2025-12-22";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "c712eb9b550fba726826e7879e3c5b0c887686d8";
    hash = "sha256-aMIB99D+5kyFw9E7YMt4eKkAF1TeWJYSbLrJ3skGEZ8=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
