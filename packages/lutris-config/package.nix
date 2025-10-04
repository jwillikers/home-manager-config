{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "lutris-config";
  version = "0-unstable-2025-10-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "lutris-config";
    rev = "e3581b7683f9cf16426b5668e20b1c4954170e73";
    hash = "sha256-sTO/7rxDJwuqv2yHwHNbwg7b3hHJ0zkfZloTmZQZPsc=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/lutris/ lutris/*.yml
    runHook postInstall
  '';
}
