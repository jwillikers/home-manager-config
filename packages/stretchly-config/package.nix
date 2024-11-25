{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2024-10-29";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "533f1fca7cdc67f365234f75d7b0f104909d67e1";
    hash = "sha256-ad7HEh81L9RiMnRtakS8fpYtkiItw6T1GK2oFAi0kLQ=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
