{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  pname = "steam-deck-auto-disable-steam-controller";
  version = "0-unstable-2024-04-05";

  src = fetchFromGitHub {
    owner = "scawp";
    repo = "Steam-Deck.Auto-Disable-Steam-Controller";
    rev = "35f1bacb16fadeade4ae7e590b3fd857edb04f25";
    hash = "sha256-zOcuMrYBHWzy9jlcMNcnNcb2TjCovAiVbSC9f3xnG5I=";
  };

  postPatch = ''
    cp ${./99-disable-steam-input.rules} 99-disable-steam-input.rules
    substituteInPlace 99-disable-steam-input.rules \
      --replace-fail "/usr/bin/disable_steam_input.sh" "${placeholder "out"}/bin/disable_steam_input.sh"
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0555 --target-directory=$out/bin disable_steam_input.sh
    install -D --mode=0644 --target-directory=$out/etc/udev/rules.d 99-disable-steam-input.rules
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
