{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "foot-config";
  version = "0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/udev/rules.d rules.d/*.rules
    runHook postInstall
  '';
}
