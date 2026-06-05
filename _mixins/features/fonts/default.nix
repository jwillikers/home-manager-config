{
  pkgs,
  ...
}:
{
  # https://yildiz.dev/posts/packing-custom-fonts-for-nixos/
  home = {
    packages = with pkgs; [
      nerd-fonts.adwaita-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.noto
      nerd-fonts.symbols-only
      corefonts
      fira
      font-awesome
      liberation_ttf

      # font-ibm-type1
      # caladea
      # symbola

      vista-fonts
      garamond-libre
      libre-caslon
      # input-fonts # License
      libre-franklin

      # tex-gyre.heros
      # tex-gyre-math.termes
      # tex-gyre.termes
      # texlivePackages.heros-otf
      # texlivePackages.termes-otf

      # texlivePackages.palatino
      # texlivePackages.zapfding
      # texlivePackages.fontawesome
      # texlivePackages.fontawesome5

      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-monochrome-emoji
      source-serif
      work-sans
    ];
  };

  gtk = {
    font = {
      name = "FiraCode Nerd Font Mono";
      size = 12;
    };
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [
        "Source Serif"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Work Sans"
        "Fira Sans"
        "Noto Color Emoji"
      ];
      monospace = [
        "FiraCode Nerd Font Mono"
        "Font Awesome 6 Free"
        "Font Awesome 6 Brands"
        "Symbola"
        "Noto Emoji"
      ];
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };
}
