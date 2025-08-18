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
      noto-fonts-emoji
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
