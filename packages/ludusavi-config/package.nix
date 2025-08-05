{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-config";
  version = "0-unstable-2025-08-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-config";
    rev = "b352744ec59a7711c62653dad3fa329e3b969017";
    hash = "sha256-Wd9jZeCeTvDNpleDgXspcY6+VPdS7EeYtYfvkUrnv+8=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
