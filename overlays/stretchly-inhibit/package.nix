{
  lib,
  makeWrapper,
  pulseaudio,
  pyright,
  python3,
  ruff,
  stdenvNoCC,
  stretchly,
}:

let
  python = python3.withPackages (ps: [ ps.jeepney ]);
in
stdenvNoCC.mkDerivation {
  pname = "stretchly-inhibit";
  version = "0.7.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  nativeCheckInputs = [
    # Pyright type checks against the dependencies of the Python interpreter in PATH.
    pyright
    python
    ruff
  ];

  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ruff format --check
    ruff check
    pyright
    python -m unittest --verbose test_stretchly_inhibit
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 stretchly_inhibit.py $out/bin/stretchly-inhibit
    substituteInPlace $out/bin/stretchly-inhibit \
      --replace-fail "#!/usr/bin/env python3" "#!${python.interpreter}"
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
    description = "Pause Stretchly breaks during online meetings, while watching videos, and optionally while away or for local multiplayer";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-inhibit";
  };
}
