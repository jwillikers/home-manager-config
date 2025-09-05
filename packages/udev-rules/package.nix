{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "udev-rules";
  version = "0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/udev/rules.d rules.d/*.rules
    runHook postInstall
  '';
}
