{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-steam-deck-config";
  version = "0-unstable-2025-08-06";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-steam-deck-config";
    rev = "f617e3d6717c3dfbe377aa5f44df9d9b84b6e851";
    hash = "sha256-N94+MASZO8pNVcoDgmcVNGsIlbPgQn7q/j+9UYUTSEo=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
