{
  clipse,
  fetchFromGitea,
  foot,
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
    rev = "9e8bc619690078166b2c137fb77286a8870ddff6";
    hash = "sha256-Igp22hkVyPJACkPeopvw8/8wzHw9IRN5SVFHCkqbE5I=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/etc/sway/config.d sway/config.d/*.conf
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/etc/sway/config.d/99-clipse.conf \
      --replace-fail "exec clipse" "exec ${lib.getExe clipse}" \
      --replace-fail "exec foot" "exec ${lib.getExe foot}"
    substituteInPlace $out/etc/sway/config.d/99-swayaudioidleinhibit.conf \
      --replace-fail "exec sway-audio-idle-inhibit" "exec ${lib.getExe sway-audio-idle-inhibit}"
    substituteInPlace $out/etc/sway/config.d/99-gtk-dark-theme.conf \
      --replace-fail "gsettings set" "${lib.getBin glib}/bin/gsettings set"
  '';
}
