{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-config";
  version = "0-unstable-2025-11-13";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "stretchly-config";
    rev = "a5fd48706edea852d9f4f0fba80a673eefe99201";
    hash = "sha256-ZO/xqzrX3rWfJw351a8YVZ++DhAIdO7WB0SvwZAUvSo=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 config.json $out/etc/Stretchly/config.json
    runHook postInstall
  '';
}
