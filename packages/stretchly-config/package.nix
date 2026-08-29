{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2026-08-29";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "0d5ab6de9110c0f9d7b291f1ab122930d8c3bf47";
    hash = "sha256-WseiIfxUJdysOFn3fhWNSuHymuQgd/H82uENuKCbuVQ=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
