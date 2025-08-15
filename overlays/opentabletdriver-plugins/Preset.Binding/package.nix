{
  buildDotnetModule,
  coreutils,
  # dotnet-sdk-wrapped,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
  zulu,
}:
buildDotnetModule (finalAttrs: {
  # stdenvNoCC.mkDerivation rec {
  pname = "Preset.Binding";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "Mrcubix";
    repo = "Preset.Binding";
    tag = finalAttrs.version;
    hash = "sha256-u/X5E/DMjYNkLWlP/pJDGOe9QR2eYhv0Br1meyRn33I=";
    fetchSubmodules = true;
  };

  dotnet-sdk = dotnetCorePackages.sdk_8_0;

  projectFile = [
    "src/Preset.Binding.csproj"
    # "OpenTabletDriver.Console"
    # "OpenTabletDriver.Daemon"
    # "OpenTabletDriver.UX.Gtk"
  ];
  nugetDeps = ./deps.json;

  nativeBuildInputs = [
    coreutils # sha256sum
    dotnetCorePackages.sdk_8_0
    zulu
  ];

  buildPhase = ''
    runHook preBuild
    bash build.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/lib/OpenTabletDriver/Plugins Preset.Binding.Zip
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/Mrcubix/Preset.Binding";
    changelog = "https://github.com/Mrcubix/Preset.Binding/releases/tag/${finalAttrs.version}";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
  };
})
