{
  fetchFromGitea,
  glib,
  lib,
  sway-audio-idle-inhibit,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "sway-config";
  version = "0-unstable-2024-10-30";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "sway-config";
    rev = "bbf3a1d56b9c7505c9c5000dcb24e7d9c99a3b36";
    hash = "sha256-NyWsax2+lZkbHrmxW8czARfoSo3HUlMwNIntYLQ9S68=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/sway/config.d sway/config.d/*.conf
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/etc/sway/config.d/99-swayaudioidleinhibit.conf \
      --replace-fail "exec sway-audio-idle-inhibit" "exec ${lib.getExe sway-audio-idle-inhibit}"
    substituteInPlace $out/etc/sway/config.d/99-gtk-dark-theme.conf \
      --replace-fail "gsettings set" "${lib.getBin glib}/bin/gsettings set"
  '';
}
