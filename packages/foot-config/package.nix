{
  fetchFromGitea,
  fish,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "foot-config";
  version = "0-unstable-2025-12-11";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "foot-config";
    rev = "07b7cc96be4625f660c1fad54b03190b47e57d20";
    hash = "sha256-fwmH14A2Z9B+6OeMsliwQaTWAQ0G7iO6czqDl65GL6w=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 foot.ini $out/etc/foot/foot.ini
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/etc/foot/foot.ini \
      --replace-fail "shell=/usr/bin/fish" "shell=${lib.getExe fish}"
  '';
}
