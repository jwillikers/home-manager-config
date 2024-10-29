{
  fetchFromGitea,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "tio-config";
  version = "0-unstable-2024-09-30";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "tio-config";
    rev = "05a9e9e48405eb62c49d177a5c3bb354efae7856";
    hash = "sha256-w6BV4gdej89ZjzjGtKLD/wlrqnrNfNo2Rgodw1itF7c=";
  };

  installPhase = ''
    install -D --mode=0644 tio/config $out/etc/tio/config
  '';
}
