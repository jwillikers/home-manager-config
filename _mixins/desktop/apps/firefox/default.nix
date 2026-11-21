{
  lib,
  ...
}:
let
  # Firefox is installed as a system Flatpak, so launch it through Flatpak.
  # --file-forwarding lets the sandbox open local files passed on the command line.
  flatpakRun = "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=firefox";
  firefoxExec = "${flatpakRun} --file-forwarding org.mozilla.firefox";
  desktopEntry = "org.mozilla.firefox.desktop";
in
# Web browser
{
  # SteamOS ships /usr/share/applications/org.mozilla.firefox.desktop, an "Install Firefox" stub
  # whose Exec only opens appstream://org.mozilla.firefox in Discover.
  # It shares the desktop file ID of the Flatpak's own entry in /var/lib/flatpak/exports/share,
  # and /usr/share comes first in XDG_DATA_DIRS, so the stub shadows the real entry and
  # launching Firefox just opens its store page instead of the browser.
  # $XDG_DATA_HOME is searched before every XDG_DATA_DIRS entry, so writing the same file ID
  # here shadows the stub in turn and restores a working launcher.
  xdg.desktopEntries."org.mozilla.firefox" = {
    name = "Firefox";
    genericName = "Web Browser";
    exec = "${firefoxExec} @@u %u @@";
    icon = "org.mozilla.firefox";
    terminal = false;
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "application/xhtml+xml"
      "application/xml"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "firefox";
      X-MultipleArgs = "false";
    };
    actions = {
      new-window = {
        name = "New Window";
        exec = "${firefoxExec} --new-window @@u %u @@";
      };
      new-private-window = {
        name = "New Private Window";
        exec = "${firefoxExec} --private-window @@u %u @@";
      };
      open-profile-manager = {
        name = "Open Profile Manager";
        exec = "${flatpakRun} org.mozilla.firefox --ProfileManager";
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Leave application/pdf alone so the system PDF viewer keeps handling documents.
      "application/xhtml+xml" = [ desktopEntry ];
      "application/xml" = [ desktopEntry ];
      "text/html" = [ desktopEntry ];
      "text/xml" = [ desktopEntry ];
      "x-scheme-handler/http" = [ desktopEntry ];
      "x-scheme-handler/https" = [ desktopEntry ];
      # Preserve the handlers that were already registered outside Home Manager.
      "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
      "x-scheme-handler/heroic" = [ "com.heroicgameslauncher.hgl.desktop" ];
    };
    associations.added = {
      "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
    };
  };

  # $BROWSER takes a command, not a desktop file ID, so point it at the Flatpak launcher.
  home.sessionVariables.BROWSER = lib.mkDefault "${flatpakRun} org.mozilla.firefox";
}
