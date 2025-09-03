{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "lutris-config";
  version = "0-unstable-2025-09-03";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "lutris-config";
    rev = "8249b24e2490aab119b15353c1b6469be21b7dec";
    hash = "sha256-8XC5yM7sv4O0qq/yBeMZWW03SwAGd2VuzdB7Y3yoi2E=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/lutris/ lutris/*.yml
    runHook postInstall
  '';
}
