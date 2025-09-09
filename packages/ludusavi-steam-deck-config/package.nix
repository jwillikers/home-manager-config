{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-steam-deck-config";
  version = "0-unstable-2025-09-09";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-steam-deck-config";
    rev = "48547f5b799eca5ed890bba9344814bbec5e1d52";
    hash = "sha256-FLIxOmq1QiT6XG6lYaCjx2EXelRD03EeAKWi/QHmYRo=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
