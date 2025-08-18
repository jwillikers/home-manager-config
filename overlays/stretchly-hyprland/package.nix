{
  bc,
  hyprland,
  jq,
  lib,
  makeWrapper,
  socat,
  stdenvNoCC,
  systemdMinimal,
}:

stdenvNoCC.mkDerivation {
  pname = "stretchly-hyprland";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -D --mode=0770 stretchly-hyprland.sh $out/bin/stretchly-hyprland.sh
    wrapProgram $out/bin/stretchly-hyprland.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          bc
          hyprland
          jq
          socat
          systemdMinimal
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Places Stretchly break windows on their respective monitors in multi-monitor Hyprland setups";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jwillikers ];
    mainProgram = "stretchly-hyprland.sh";
  };
}
