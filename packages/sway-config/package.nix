{
  fetchFromGitea,
  glib,
  sway-audio-idle-inhibit,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "sway-config";
  version = "0-unstable-2024-10-17";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "sway-config";
    rev = "f185a7d0df02a9206e0ca4b65e4e30577263599e";
    hash = "sha256-KWHLVmMnKFoirQm3Whb9AY08A8t5+ip9ziBW4WyPC2A=";
  };

  installPhase = ''
    install -D --mode=0644 --target-directory=$out/etc/sway/config.d sway/config.d/*.conf
  '';

  postFixup = ''
    substituteInPlace $out/etc/sway/config.d/99-swayaudioidleinhibit.conf \
      --replace-fail "exec sway-audio-idle-inhibit" "exec ${sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit"
    substituteInPlace $out/etc/sway/config.d/99-gtk-dark-theme.conf \
      --replace-fail "gsettings set" "${glib}/bin/gsettings set"
  '';
}
