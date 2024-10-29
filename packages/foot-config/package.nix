{
  fetchFromGitea,
  fish,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "foot-config";
  version = "0-unstable-2024-09-30";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "foot-config";
    rev = "c77c4a82d67a558c75670f8402b0192de33e3e80";
    hash = "sha256-3PvPShPbez/HNQ/BSQ5xAQVmgxEGA2u83yuUsoko6lA=";
  };

  installPhase = ''
    install -D --mode=0644 foot.ini $out/etc/foot/foot.ini
  '';

  postFixup = ''
    substituteInPlace $out/etc/foot/foot.ini \
      --replace-fail "shell=/usr/bin/fish" "shell=${fish}/bin/fish"
  '';
}
