{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "tio-config";
  version = "0-unstable-2026-08-01";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "tio-config";
    rev = "2bae26d7e97a3b94e2734a01327bdcc4316047a4";
    hash = "sha256-pYzMpw374OCTbGWdwXuYOGGtWCXCEEBOS8588nhdOQU=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 tio/config $out/etc/tio/config
    runHook postInstall
  '';
}
