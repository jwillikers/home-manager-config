{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "lutris-config";
  version = "0-unstable-2025-09-21";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "lutris-config";
    rev = "7e81f9ad78706d1717f08c5e601f32df4508b8bc";
    hash = "sha256-MSuZZUawZmyd0p1egGYtjrzdrQA+QfKHeLLjqFz0mB0=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/lutris/ lutris/*.yml
    runHook postInstall
  '';
}
