{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2025-07-28";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "ed194abf9e02c79cf2ad5a42e2d5773776ed2abc";
    hash = "sha256-7dDEI4leLgrma+LkUNJnjeSZp0Qp6AbV0e0fAbTWH5A=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
