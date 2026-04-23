{
  fetchFromGitea,
  fish,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "foot-config";
  version = "0-unstable-2026-04-23";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "foot-config";
    rev = "c76926f59635e4512f0626f39ce09630e0a5f7ac";
    hash = "sha256-Zmdwm//YOt06XlSJZmMs8aAn40rfhwE3iwzSYqa1/zc=";
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
