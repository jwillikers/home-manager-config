{
  hyprland,
  jq,
  lib,
  stdenvNoCC,
  systemdMinimal,
  wrapProgram,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-hyprland";
  version = "0.0.0";

  src = ./.;

  nativeBuildInputs = [
    wrapProgram
  ];

  installPhase = ''
    runHook preInstall
    install -D --mode=0770 stretchly-hyprland.sh $out/bin/stretchly-hyprland.sh
    wrapProgram $out/bin/stretchly-hyprland.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          hyprland
          jq
          systemdMinimal
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Places Stretchly break windows on their respective monitors in multi-monitor Hyprland setups";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-hyprland.sh";
  };
}
