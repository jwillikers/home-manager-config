{
  fetchFromGitea,
  gawk,
  inputplumber,
  lib,
  makeWrapper,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "inputplumber-profiles";
  version = "0-unstable-2025-10-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "inputplumber-profiles";
    rev = "6abb1dddc2ebc994d946d27de1ed1abfcdf61d53";
    hash = "sha256-6sp2YQcLhOOjzbbvobfdY6cOuMcyNH8MyZ9d18WnCcM=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir --parents $out/etc/inputplumber
    cp --recursive devices.d profiles.d $out/etc/inputplumber
    install -D --mode=0755 --target-directory=$out/bin scripts/*.sh
    wrapProgram $out/bin/lutris-inputplumber-pre-launch.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          gawk
          inputplumber
        ]
      }
    wrapProgram $out/bin/lutris-inputplumber-post-exit.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          gawk
          inputplumber
        ]
      }
    runHook postInstall
  '';
}
