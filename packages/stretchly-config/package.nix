{
  fetchFromGitea,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2024-10-12";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "5aed136cef7ed2d98bfd234c6a2da839806d0220";
    hash = "sha256-SXtS2IDzhekH/G4/4BuBXUHe3tXVsqr6cTb+T9CNNzU=";
  };

  installPhase = ''
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
  '';
}
