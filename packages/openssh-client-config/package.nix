{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "openssh-client-config";
  version = "0-unstable-2026-06-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "openssh-client-config";
    rev = "188a20f16cd12619ffd51de0993d70445488dca5";
    hash = "sha256-9FY8IhPM4ey5ieEYNIS1r1lT49nOodpJ0wbhkh9NO8c=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/ssh/ssh_config.d ssh/config.d/*
    runHook postInstall
  '';
}
