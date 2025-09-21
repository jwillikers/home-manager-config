{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-config";
  version = "0-unstable-2025-09-20";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-config";
    rev = "41065127e2674b90711c976b9b105a6b220c1c71";
    hash = "sha256-I5I0wMYjiWG+A8n0y4sRLVTvGVz58t8lqBm+u6d5a38=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
