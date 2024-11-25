{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "tio-config";
  version = "0-unstable-2024-11-06";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "tio-config";
    rev = "7a852cdf5a2396dd2e356f65dad6166b94d26340";
    hash = "sha256-hoq+IUlVS16HiqqlIm7PERN0KwDZbbX0OxNXmnOuW4o=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 tio/config $out/etc/tio/config
    runHook postInstall
  '';
}
