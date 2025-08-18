{
  lib,
  pulseaudio,
  stdenvNoCC,
  stretchly,
  systemdMinimal,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-inhibit";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -D --mode=0770 stretchly-inhibit.sh $out/bin/stretchly-inhibit.sh
    wrapProgram $out/bin/stretchly-inhibit.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          pulseaudio
          stretchly
          systemdMinimal
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Inhibit Stretchly breaks when audio devices or web cameras are active.";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-inhibit.sh";
  };
}
