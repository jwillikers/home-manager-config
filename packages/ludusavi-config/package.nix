{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-config";
  version = "0-unstable-2025-09-29";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-config";
    rev = "d644d1dceafd93004669a94c538bf2cdb694f26e";
    hash = "sha256-yJpS3Ah6fuCYdN+hK4/CHrqS0Q0KPO2FMWF7xFLjU9I=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
