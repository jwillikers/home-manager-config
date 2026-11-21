{
  lib,
  lua5_5,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-hyprland";
  version = "0.2.0";

  src = ./.;

  # Hyprland embeds Lua 5.5.
  nativeCheckInputs = [ lua5_5 ];

  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    lua test-stretchly-hyprland.lua stretchly-hyprland.lua
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/share/stretchly-hyprland stretchly-hyprland.lua
    runHook postInstall
  '';

  meta = {
    description = "Hyprland Lua config that places Stretchly break windows on their respective monitors";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
  };
}
