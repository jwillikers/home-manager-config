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
    rev = "b9ffd4c66e188b1a0f4c82f45d6c053590e244d7";
    hash = "sha256-TwEWj8pTIE6v+k04gAXcN/Oc+uKjPn/KHmlLE3sVPg0=";
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
