{
  fetchFromGitea,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "sublime-merge-config";
  version = "0-unstable-2024-10-12";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "sublime-merge-config";
    rev = "414273929c1dba74f5f138ca9cffd9dcf931838c";
    hash = "sha256-5t+tOhLSyp+FNPcUVS0BQukgDlf3Yg0n6dypTE4SvvA=";
  };

  # todo Install Sublime Merge license key somehow.
  installPhase = ''
    install -D --mode=0644 --target-directory=$out/etc/sublime-merge/Packages/User User/*.sublime-settings
  '';
}
