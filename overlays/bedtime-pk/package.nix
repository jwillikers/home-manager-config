{
  gawk,
  inotify-tools,
  lib,
  stdenvNoCC,
  systemdMinimal,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "bedtime-pk";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -D --mode=0770 bedtime-pk.sh $out/bin/bedtime-pk.sh
    wrapProgram $out/bin/bedtime-pk.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          gawk
          inotify-tools
          systemdMinimal
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Kill certain processes during bed time.";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "bedtime-pk.sh";
  };
}
