{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "ludusavi-config";
  version = "0-unstable-2025-09-03";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "ludusavi-config";
    rev = "059ce727cafc082dac586f37b45af41bf209977a";
    hash = "sha256-Hr9sF3IxIvXvthfrhGwTmCSJluK452M+2QAK2TO5I1g=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 ludusavi/config.yaml $out/etc/ludusavi/config.yaml
    runHook postInstall
  '';
}
