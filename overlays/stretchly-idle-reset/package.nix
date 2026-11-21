{
  lib,
  python3,
  stdenvNoCC,
}:

let
  python = python3.withPackages (ps: [ ps.evdev ]);
in
stdenvNoCC.mkDerivation {
  pname = "stretchly-idle-reset";
  version = "0.2.0";

  src = ./.;

  nativeCheckInputs = [
    python
    python3.pkgs.flake8
  ];

  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    # Allow long lines.
    flake8 --extend-ignore=E501 stretchly-idle-reset.py test_stretchly_idle_reset.py
    python -m unittest --verbose test_stretchly_idle_reset
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 stretchly-idle-reset.py $out/bin/stretchly-idle-reset
    substituteInPlace $out/bin/stretchly-idle-reset \
      --replace-fail "#!/usr/bin/env python3" "#!${python.interpreter}"
    runHook postInstall
  '';

  meta = {
    description = "Reset Stretchly breaks after returning from a long period without any input, gamepads included";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-idle-reset";
  };
}
