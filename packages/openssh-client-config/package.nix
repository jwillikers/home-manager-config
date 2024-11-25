{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "openssh-client-config";
  version = "0-unstable-2024-09-30";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "openssh-client-config";
    rev = "9e5e2df21e7b826a1b68e260271938b713aea6fe";
    hash = "sha256-Wq3IUx6XZOmU4yzPPcwF3DY2r8wd1fFjjbP2tEkIqOs=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/ssh/ssh_config.d ssh/config.d/*
    runHook postInstall
  '';
}
