{
  fetchFromGitea,
  glib,
  sway-audio-idle-inhibit,
  stdenv,
}:

stdenv.mkDerivation {
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
    install -D --mode=0644 --target-directory=$out/etc/sway/config.d sway/config.d/*.conf
  '';

  postFixup = ''
    substituteInPlace $out/etc/sway/config.d/99-swayaudioidleinhibit.conf \
      --replace-fail "exec sway-audio-idle-inhibit" "exec ${sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit"
    substituteInPlace $out/etc/sway/config.d/99-gtk-dark-theme.conf \
      --replace-fail "gsettings set" "${glib}/bin/gsettings set"
  '';
}
