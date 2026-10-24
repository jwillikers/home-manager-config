{
  inotify-tools,
  jq,
  lib,
  libnotify,
  stdenvNoCC,
  systemdMinimal,
  makeWrapper,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  pname = "systemd-bedtime-timer";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/systemd/system/ bedtime.service bedtime.timer
    install -D --mode=0755 --target-directory=$out/bin/ bedtime.sh
    wrapProgram $out/bin/bedtime.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          inotify-tools
          jq
          libnotify
          systemdMinimal
        ]
      }
    install -D --mode=0644 --target-directory=$out/etc/systemd-bedtime-timer/ config.json
    runHook postInstall
  '';

  meta = {
    description = "Systemd files to sleep the system during bedtime.";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
  };
})
