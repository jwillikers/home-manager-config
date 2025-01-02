{
  clipse,
  fetchFromGitea,
  glib,
  lib,
  sway-audio-idle-inhibit,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "sway-config";
  version = "0-unstable-2025-01-02";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "sway-config";
    rev = "52f6f11250a0b483ba0995716b35cecdca3a5e6c";
    hash = "sha256-tnaUKpYKhuIWpvMClvgnL7TFclX27OM6pSOz77s+iR8=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/sway/config.d sway/config.d/*.conf
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/etc/sway/config.d/99-clipse.conf \
      --replace-fail "exec clipse" "exec ${lib.getExe clipse}"
    substituteInPlace $out/etc/sway/config.d/99-swayaudioidleinhibit.conf \
      --replace-fail "exec sway-audio-idle-inhibit" "exec ${lib.getExe sway-audio-idle-inhibit}"
    substituteInPlace $out/etc/sway/config.d/99-gtk-dark-theme.conf \
      --replace-fail "gsettings set" "${lib.getBin glib}/bin/gsettings set"
  '';
}
