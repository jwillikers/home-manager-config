{
  cmake,
  kdePackages,
  mold-wrapped,
  ninja,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "kidlestretchly";
  version = "0.0.1";

  src = ./.;

  buildInputs = [
    kdePackages.kidletime
    kdePackages.qtbase
  ];

  nativeBuildInputs = [
    cmake
    mold-wrapped
    ninja
    kdePackages.wrapQtAppsHook
  ];

  cmakeFlags = [
    "--preset=minimal"
    "-DCMAKE_LINKER_TYPE=MOLD"
  ];

  meta = {
    mainProgram = "kidlestretchly";
  };
}
