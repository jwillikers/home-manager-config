{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "lutris-config";
  version = "0-unstable-2025-10-03";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "lutris-config";
    rev = "98ccab3b11750bb9e383d11d0ef766f4328c8425";
    hash = "sha256-tNNiP/aiJ5nlRd2Mm5l5PR0/ER9PEk4SMZyGbtA14dI=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/lutris/ lutris/*.yml
    runHook postInstall
  '';
}
