{
  lib,
  lua5_5,
  selene,
  stdenvNoCC,
  stylua,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-hyprland";
  version = "0.2.0";

  src = ./.;

  nativeCheckInputs = [
    # Hyprland embeds Lua 5.5.
    lua5_5
    selene
    stylua
  ];

  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    stylua --check .
    selene .
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
