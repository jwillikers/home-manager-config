{
  lib,
  pyright,
  python3,
  ruff,
  stdenvNoCC,
}:

let
  python = python3.withPackages (ps: [ ps.evdev ]);
in
stdenvNoCC.mkDerivation {
  pname = "input-idle-monitor";
  version = "0.3.0";

  src = ./.;

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
    python -m unittest --verbose test_input_idle_monitor
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 input_idle_monitor.py $out/bin/input-idle-monitor
    substituteInPlace $out/bin/input-idle-monitor \
      --replace-fail "#!/usr/bin/env python3" "#!${python.interpreter}"
    runHook postInstall
  '';

  meta = {
    description = "Report when the user goes away and returns, counting input from every device, gamepads included";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "input-idle-monitor";
  };
}
