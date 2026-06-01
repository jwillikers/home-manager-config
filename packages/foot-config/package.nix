{
  fetchFromGitea,
  fish,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "foot-config";
  version = "0-unstable-2026-06-01";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "foot-config";
    rev = "71b0c204880b6f5e067a54477846ab8ac37d6620";
    hash = "sha256-c+avQc6yi/cZQj1pzC+rCNJp1gerq66o00k8stpqIC0=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 foot.ini $out/etc/foot/foot.ini
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/etc/foot/foot.ini \
      --replace-fail "shell=/usr/bin/fish" "shell=${lib.getExe fish}"
  '';
}
