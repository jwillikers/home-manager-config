{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "openssh-client-config";
  version = "0-unstable-2025-08-19";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "openssh-client-config";
    rev = "5c4cb31cd00a4ff918e1c131ef7638790f626657";
    hash = "sha256-mdZC6WtQf9xVt4F78p6xyrbNTeBcA+bq5vYoDYajSEk=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/ssh/ssh_config.d ssh/config.d/*
    runHook postInstall
  '';
}
