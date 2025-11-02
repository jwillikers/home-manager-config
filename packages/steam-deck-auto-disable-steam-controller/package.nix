{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
  writeText,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "steam-deck-auto-disable-steam-controller";
  version = "0-unstable-2024-04-05";

  src = fetchFromGitHub {
    owner = "scawp";
    repo = "Steam-Deck.Auto-Disable-Steam-Controller";
    rev = "35f1bacb16fadeade4ae7e590b3fd857edb04f25";
    hash = "sha256-zOcuMrYBHWzy9jlcMNcnNcb2TjCovAiVbSC9f3xnG5I=";
  };

  udevRules = writeText "99-disable-steam-input.rules" ''
    KERNEL=="input*", SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", ACTION=="add", RUN+="${placeholder "out"}/bin/disable_steam_input.sh disable %k %E{NAME} %E{UNIQ} %E{PRODUCT}"
    KERNEL=="input*", SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", ACTION=="remove", RUN+="${placeholder "out"}/bin/disable_steam_input.sh enable %k %E{NAME} %E{UNIQ} %E{PRODUCT}"
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0555 --target-directory=$out/bin/disable_steam_input.sh disable_steam_input.sh
    install -D --mode=0644 ${finalAttrs.udevRules} $out/etc/udev/rules.d/99-disable-steam-input.rules
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/scawp/Steam-Deck.Auto-Disable-Steam-Controller";
    platforms = lib.platforms.linux;
    # DBAD Public License
    # license = lib.licenses.;
    mainProgram = "disable_steam_input.sh";
  };
})
