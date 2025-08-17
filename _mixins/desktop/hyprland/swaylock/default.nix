{
  pkgs,
  ...
}:
{
  programs.swaylock = {
    enable = true;
    # Swaylock must be installed on the system.
    # Wayblue currently uses Swaylock and not Hyprlock due to packaging issues in Fedora 42.
    # Mixing /etc/pam.d/login from Fedora with PAM modules from Nix breaks things.
    # PAM unable to dlopen(/nix/store/.../lib/security/pam_fprintd.so)
    package = pkgs.runCommandLocal "empty" { } "mkdir $out";
    settings = {
      image = "/usr/share/backgrounds/default-dark.jxl";
      scaling = "fill";
    };
  };
}
