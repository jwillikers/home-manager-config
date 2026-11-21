{
  lib,
  makeWrapper,
  pulseaudio,
  python3,
  ruff,
  stdenvNoCC,
  stretchly,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-inhibit";
  version = "0.2.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    python3
    ruff
  ];

  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ruff format --check
    ruff check
    python -m unittest --verbose test_stretchly_inhibit
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 stretchly-inhibit.py $out/bin/stretchly-inhibit
    substituteInPlace $out/bin/stretchly-inhibit \
      --replace-fail "#!/usr/bin/env python3" "#!${python3.interpreter}"
    wrapProgram $out/bin/stretchly-inhibit \
      --prefix PATH : ${
        lib.makeBinPath [
          pulseaudio
          stretchly
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Pause Stretchly breaks while a microphone is in use, ignoring games";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-inhibit";
  };
}
