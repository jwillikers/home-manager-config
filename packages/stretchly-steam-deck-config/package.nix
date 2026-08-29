{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-steam-deck-config";
  version = "0-unstable-2026-08-29";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-steam-deck-config";
    rev = "e430e1eaaffce621afb6b4a8af84a0b2e0f11e16";
    hash = "sha256-44zgbgScXKwobNh8yqjRNvtNmihaTzhrVvAJZRHjuME=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
