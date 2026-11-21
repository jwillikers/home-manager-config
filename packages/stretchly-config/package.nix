{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2026-11-20";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "77be02f6edec83c5723ba3cbe91853fac6b1309a";
    hash = "sha256-I8yfH5b6LPRvBXPQPHwUkP4xDxN4KRoqp+M5ZH4koHk=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
