{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2026-03-16";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "dd2c0d8410f66fad132fbda0afcf4798e5406703";
    hash = "sha256-aMIB99D+5kyFw9E7YMt4eKkAF1TeWJYSbLrJ3skGEZ8=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
