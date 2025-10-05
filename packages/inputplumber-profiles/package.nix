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
  version = "0-unstable-2025-10-05";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "inputplumber-profiles";
    rev = "e006ec8a238075a19dbece1dad8c984f6ef5fe33";
    hash = "sha256-JE7APAMsjAWyLya7q2A6vBCfYLS0CTRyHAFgH+9obEQ=";
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
