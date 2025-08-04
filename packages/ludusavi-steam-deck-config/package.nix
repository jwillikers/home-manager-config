{
  fetchFromGitea,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "lutris-config";
  version = "0-unstable-2025-08-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "lutris-config";
    rev = "536d279f3c0a4c6882a5e2b094dda8c2ca49f5d";
    hash = lib.fakeHash;
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/lutris/ lutris/*.yml
    runHook postInstall
  '';
}
