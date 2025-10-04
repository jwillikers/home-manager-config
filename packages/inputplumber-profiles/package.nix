{
  fetchFromGitea,
  inputplumber,
  lib,
  makeWrapper,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "inputplumber-profiles";
  version = "0-unstable-2025-10-03";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "inputplumber-profiles";
    rev = "61e6af1fc01826a4f325785a5ef5069eca06bda3";
    hash = "sha256-KpGoJ5++NINry/MgTsuE9HrIDki830yKqmet51lBIm8=";
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
          inputplumber
        ]
      }
    wrapProgram $out/bin/lutris-inputplumber-post-exit.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          inputplumber
        ]
      }
    runHook postInstall
  '';
}
