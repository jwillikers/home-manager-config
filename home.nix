{
  config,
  inputs,
  lib,
  nixgl,
  packages,
  pkgs,
  ...
}:
let
  username = "jordan";
  homeDirectory = "/home/${username}";
  flatpaks = [
    "com.bitwarden.desktop"
    "com.calibre_ebook.calibre"
    "com.discordapp.Discord"
    "com.github.geigi.cozy"
    "com.github.iwalton3.jellyfin-media-player"
    "com.github.tchx84.Flatseal"
    "com.nextcloud.desktopclient.nextcloud"
    "de.haeckerfelix.Fragments"
    "im.riot.Riot"
    "io.gitlab.azymohliad.WatchMate"
    "io.gitlab.news_flash.NewsFlash"
    "net.hovancik.Stretchly"
    "net.werwolv.ImHex"
    "org.fedoraproject.MediaWriter"
    # "org.fritzing.Fritzing"
    "org.gnome.Maps"
    # "org.gnome.Calendar"
    # "org.gnome.Contacts"
    # "org.gnome.Lollypop"
    # "org.gnome.Podcasts"
    # "org.gnome.Seahorse"
    # "org.gnome.Todo"
    "org.gtk.Gtk3theme.Adwaita-dark"
    "org.kde.itinerary"
    "org.kde.krita"
    # "org.keepassxc.KeePassXC"
    "org.libreoffice.LibreOffice"
    "org.mozilla.Thunderbird"
    "org.raspberrypi.rpi-imager"
    "org.thonny.Thonny"
    "org.torproject.torbrowser-launcher"
    "us.zoom.Zoom"
    # "com.valve.Steam"
  ];
in
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
    };
  };

  gtk = {
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    enable = true;
    gtk2 = {
      configLocation = "${config.xdg.configHome}/.gtkrc-2.0";
      extraConfig = ''
        gtk-application-prefer-dark-theme = 1
        gtk-button-images = 1
      '';
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-button-images = 1;
      };
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  fonts.fontconfig.enable = true;

  home = {
    inherit homeDirectory username;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.

    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "Noto" ]; })
      asciidoctor
      deadnix # Nix dead code finder
      gcr
      # h # Modern Unix autojump for git projects
      just
      libtree
      net-snmp
      nil
      nixfmt-rfc-style # Nix code formatter
      nixpkgs-review # Nix code review
      nix-prefetch-scripts # Nix code fetcher
      nix-tree
      nu_scripts
      nurl # Nix URL fetcher
      pre-commit
      (config.lib.nixGL.wrap sublime-merge)
      sway-audio-idle-inhibit
      tailscale
      tio
      wl-clipboard-rs
    ];

    sessionVariables = {
      EDITOR = "vim";
      MANPAGER = "sh -c 'col --no-backspaces --spaces | bat --language man'";
      MANROFFOPT = "-c";
      MICRO_TRUECOLOR = "1";
      PAGER = "bat";
      SYSTEMD_EDITOR = "vim";
      VISUAL = "vim";
    };

    activation = {
      flathub = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run /usr/bin/sudo ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system $VERBOSE_ARG \
          flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
      flatpaks = lib.hm.dag.entryAfter [ "flathub" ] (
        builtins.concatStringsSep "\n" (
          builtins.map (flatpak: ''
            run /usr/bin/sudo ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG install --noninteractive --system flathub \
              ${flatpak}
          '') flatpaks
        )
      );
      flatpakTheme =
        lib.hm.dag.entryAfter
          [
            "flatpaks"
            "dconfSettings"
          ]
          ''
            COLOR_SCHEME=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/color-scheme | sed -e "s/'//g")
            GTK_THEME=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/gtk-theme | sed -e "s/'//g")
            ICON_THEME=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/icon-theme | sed -e "s/'//g")
            XCURSOR_THEME=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/cursor-theme | sed -e "s/'//g")
            if [ "$COLOR_SCHEME" == "prefer-dark" ]; then
              GTK_THEME="$GTK_THEME:dark"
            fi
            run /usr/bin/sudo ${pkgs.flatpak}/bin/flatpak override --env=GTK_THEME="$GTK_THEME"
            run /usr/bin/sudo ${pkgs.flatpak}/bin/flatpak override --env=ICON_THEME="$ICON_THEME"
            run /usr/bin/sudo ${pkgs.flatpak}/bin/flatpak override --env=XCURSOR_THEME="$XCURSOR_THEME"
          '';

      # Symlinking the Stretchly config won't work.
      # It's also necessary to install the config when Stretchly isn't running.
      stretchly = lib.hm.dag.entryAfter [ "flatpaks" ] ''
        # We don't want the cmp command to cause the script to fail.
        set +e
        cmp --silent \
          "${packages.stretchly-config}/etc/Stretchly/config.json" \
          ".var/app/net.hovancik.Stretchly/config/Stretchly/config.json"
        exit_status=$?
        set -e
        if [ $exit_status -eq 1 ]; then
          service_running=0
          if ${pkgs.procps}/bin/pgrep --ignore-case Stretchly >/dev/null; then
            if ${pkgs.systemdMinimal}/bin/systemctl --user is-active net.hovancik.Stretchly.service >/dev/null; then
              service_running=1
              run ${pkgs.systemdMinimal}/bin/systemctl --user stop net.hovancik.Stretchly.service
            else
              run ${pkgs.procps}/bin/pkill --ignore-case Stretchly
            fi
          else
            run ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG run net.hovancik.Stretchly &>/dev/null &
            run sleep 10
            run ${pkgs.procps}/bin/pkill --ignore-case Stretchly
          fi
          run sleep 1
          run mkdir --parents .var/app/net.hovancik.Stretchly/config/Stretchly
          run install -D --mode=0644 $VERBOSE_ARG \
              "${packages.stretchly-config}/etc/Stretchly/config.json" \
              ".var/app/net.hovancik.Stretchly/config/Stretchly/config.json"
          if [ "$service_running" -eq 1 ]; then
            run ${pkgs.systemdMinimal}/bin/systemctl --user start net.hovancik.Stretchly.service
          else
            run setsid ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG run net.hovancik.Stretchly &>/dev/null &
          fi
        fi
      '';
    };

    file = {
      "${config.xdg.configHome}/foot/foot.ini".source = packages.foot-config + "/etc/foot/foot.ini";
      "${config.xdg.configHome}/sublime-merge/Packages/User".source =
        packages.sublime-merge-config + "/etc/sublime-merge/Packages/User";
      "${config.xdg.configHome}/sway/config.d" = {
        source = packages.sway-config + "/etc/sway/config.d";
        onChange = "${pkgs.sway}/bin/swaymsg reload";
      };
      "${config.xdg.configHome}/tio/config".source = packages.tio-config + "/etc/tio/config";
      "${config.xdg.configHome}/vim/vimrc".source = packages.vim-config + "/etc/vim/vimrc";
      ".ssh/config.d".source = packages.openssh-client-config + "/etc/ssh/ssh_config.d";
      # "${config.xdg.configHome}/fish/functions/h.fish".text = builtins.readFile ./_mixins/configs/h.fish;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    package = pkgs.nix;
    # A lot of these should instead to be managed system-wide, right?
    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      # Don't use the temp directory as that requires a lot of RAM.
      build-dir = "/var/tmp/nix-daemon";
      cores = 4;
      # On x86_64 for emulation.
      # todo: Set this only if/then.
      extra-platforms = "aarch64-linux";
      extra-trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
      extra-trusted-substituters = [ "https://cache.lix.systems" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
      max-jobs = 4;
      warn-dirty = false;
    };
  };

  nixGL = {
    defaultWrapper = "mesa";
    installScripts = [
      "mesa"
      # NVIDIA requires using the --impure flag.
      # So don't use NVIDIA.
      # "nvidiaPrime"
    ];
    # offloadWrapper = "nvidiaPrime";
    inherit (nixgl) packages;
    vulkan.enable = true;
  };

  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Solarized (dark)";
      };
    };
    carapace = {
      enable = true;
    };
    # dircolors = {
    #   enable = true;
    #   enableBashIntegration = true;
    #   enableFishIntegration = true;
    #   enableZshIntegration = true;
    # };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fish = {
      enable = true;
      shellInit = ''
        # Colorscheme: Solarized Dark
        set -U fish_color_normal normal
        set -U fish_color_command 93a1a1
        set -U fish_color_quote 657b83
        set -U fish_color_redirection 6c71c4
        set -U fish_color_end 268bd2
        set -U fish_color_error dc322f
        set -U fish_color_param 839496
        set -U fish_color_comment 586e75
        set -U fish_color_match --background=brblue
        set -U fish_color_selection white --bold --background=brblack
        set -U fish_color_search_match bryellow --background=black
        set -U fish_color_history_current --bold
        set -U fish_color_operator 00a6b2
        set -U fish_color_escape 00a6b2
        set -U fish_color_cwd green
        set -U fish_color_cwd_root red
        set -U fish_color_valid_path --underline
        set -U fish_color_autosuggestion 586e75
        set -U fish_color_user brgreen
        set -U fish_color_host normal
        set -U fish_color_cancel --reverse
        set -U fish_pager_color_prefix cyan --underline
        set -U fish_pager_color_progress brwhite --background=cyan
        set -U fish_pager_color_completion B3A06D
        set -U fish_pager_color_description B3A06D
        set -U fish_pager_color_selected_background --background=brblack
        set -U fish_pager_color_selected_description
        set -U fish_pager_color_selected_completion
        set -U fish_pager_color_secondary_completion
        set -U fish_pager_color_secondary_prefix
        set -U fish_pager_color_background
        set -U fish_color_host_remote
        set -U fish_color_keyword
        set -U fish_pager_color_secondary_background
        set -U fish_pager_color_secondary_description
        set -U fish_pager_color_selected_prefix
        set -U fish_color_option
      '';
    };

    foot.enable = true;
    git = {
      delta = {
        enable = true;
        options = {
          decorations = {
            commit-decoration-style = "blue ol";
            commit-style = "raw";
            file-style = "omit";
            hunk-header-decoration-style = "blue box";
            hunk-header-file-style = "red";
            hunk-header-line-number-style = "\"#067a00\"";
            hunk-header-style = "file line-number syntax";
          };
          features = "decorations";
          interactive.keep-plus-minus-markers = false;
        };
      };
      enable = true;
      extraConfig = {
        branch.sort = "-committerdate";
        color.ui = "auto";
        commit.gpgSign = true;
        core = {
          editor = "${pkgs.vscode}/bin/code --wait";
          pager = "${pkgs.delta}/bin/delta";
        };
        credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";
        diff = {
          algorithm = "histogram";
          colorMoved = "default";
        };
        fetch.prune = true;
        init = {
          defaultBranch = "main";
        };
        merge = {
          conflictstyle = "diff3";
          tool = "${pkgs.sublime-merge}/bin/smerge";
        };
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          gpgSign = "if-asked";
        };
        rebase.rebaseMerges = true;
        rerere.enabled = true;
        tag.gpgSign = true;
      };
      includes = [
        {
          condition = "gitdir:~/Projects/Work/";
          contents = {
            commit.gpgSign = false;
            push.gpgSign = false;
            tag.gpgSign = false;
            user.email = "user@example.com";
            user.signingKey = null;
          };
        }
      ];
      signing = {
        key = "A6AB406AF5F1DE02CEA3B6F09FB42B0E7F657D8C";
        signByDefault = true;
      };
      userEmail = "jordan@jwillikers.com";
      userName = "Jordan Williams";
    };
    gpg = {
      enable = true;
      # Required on Fedora Sway Atomic.
      settings = {
        use-keyboxd = true;
      };
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # nix-index.enable = true;
    nushell = {
      enable = true;
    };
    ssh = {
      enable = true;
      includes = [ "~/.ssh/config.d/*.conf" ];
    };
    starship = {
      enable = true;
    };
    vim = {
      enable = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [
        vim-solarized8
      ];
    };
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        # "1dot75cm.RPMSpec"
        asciidoctor.asciidoctor-vscode
        bbenoist.nix
        # bilelmoussaoui.flatpak-vscode
        charliermarsh.ruff
        # cheshirekow.cmake-format
        # chrislajoie.icinga-language
        # chrislajoie.vscode-modelines
        coolbear.systemd-unit-file
        # DavidAnson.vscode-markdownlint
        # EditorConfig.EditorConfig
        # ESPHome.esphome-vscode
        github.vscode-github-actions
        # GitHub.vscode-pull-request-github
        golang.go
        # hangxingliu.vscode-systemd-support
        # ibecker.treefmt-vscode
        jnoortheen.nix-ide
        jock.svg
        # lextudio.restructuredtext
        llvm-vs-code-extensions.vscode-clangd
        # luggage66.AWK
        mads-hartmann.bash-ide-vscode
        mesonbuild.mesonbuild
        mkhl.direnv
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cmake-tools
        ms-vscode.cpptools-extension-pack
        nefrob.vscode-just-syntax
        redhat.vscode-xml
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        skyapps.fish-vscode
        streetsidesoftware.code-spell-checker
        # stxr.iconfont-preview
        tamasfe.even-better-toml
        tekumara.typos-vscode
        thenuprojectcontributors.vscode-nushell-lang
        timonwong.shellcheck
        # tuxtina.json2yaml
        vscodevim.vim
        # zamerick.vscode-caddyfile-syntax
      ];
    };
  };

  # https://dl.thalheim.io/
  # sops = lib.mkIf (username == "jordan") {
  #   age = {
  #     keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  #     generateKey = false;
  #   };
  #   defaultSopsFile = ../secrets/secrets.yaml;
  #   secrets = {
  #     asciinema.path = "${config.home.homeDirectory}/.config/asciinema/config";
  #     atuin_key.path = "${config.home.homeDirectory}/.local/share/atuin/key";
  #     gh_token = { };
  #     gpg_private = { };
  #     gpg_public = { };
  #     gpg_ownertrust = { };
  #     hueadm.path = "${config.home.homeDirectory}/.hueadm.json";
  #     obs_secrets = { };
  #     ssh_config.path = "${config.home.homeDirectory}/.ssh/config";
  #     ssh_key.path = "${config.home.homeDirectory}/.ssh/id_rsa";
  #     ssh_pub.path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
  #     ssh_semaphore_key.path = "${config.home.homeDirectory}/.ssh/id_rsa_semaphore";
  #     ssh_semaphore_pub.path = "${config.home.homeDirectory}/.ssh/id_rsa_semaphore.pub";
  #     transifex.path = "${config.home.homeDirectory}/.transifexrc";
  #   };
  # };

  services = {
    # flatpak = {
    #   enable = true;
    #   packages = flatpaks;
    #   # todo For system-wide installations, this might be nice.
    #   # uninstallUnmanaged = true;
    #   update.auto = {
    #     enable = true;
    #     onCalendar = "daily";
    #   };
    # };
    gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  systemd.user = {
    services = {
      "com.nextcloud.desktopclient.nextcloud" = {
        Unit = {
          Description = "Run the Nextcloud Desktop Client";
          After = [
            "graphical-session.target"
            "nss-lookup.target"
          ];
          Requires = [ "graphical-session.target" ];
          # Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${pkgs.flatpak}/bin/flatpak run com.nextcloud.desktopclient.nextcloud --background";
          ExecStop = "${pkgs.flatpak}/bin/flatpak kill com.nextcloud.desktopclient.nextcloud";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      "im.riot.Riot" = {
        Unit = {
          Description = "Start the Element Flatpak in the background";
          After = [
            "graphical-session.target"
            "nss-lookup.target"
          ];
          Requires = [ "graphical-session.target" ];
          # Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "simple";
          # Can't use Nix's flatpak command with electron apps for reasons.
          ExecStart = "/usr/bin/flatpak run im.riot.Riot --hidden";
          ExecStop = "/usr/bin/flatpak kill im.riot.Riot";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          RestrictRealtime = true;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      "net.hovancik.Stretchly" = {
        Unit = {
          Description = "Start Stretchly";
          After = [ "graphical-session.target" ];
          Requires = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStartPre = "/bin/sleep 1";
          # Can't use Nix's flatpak command with electron apps for reasons.
          ExecStart = "/usr/bin/flatpak run net.hovancik.Stretchly";
          ExecStop = "/usr/bin/flatpak kill net.hovancik.Stretchly";
          Restart = "on-failure";
          RestartSec = 10;
          KillMode = "process";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      "nix-garbage-collection" = {
        Unit = {
          Description = "Initiate Nix garbage collection";
        };

        Service = {
          Type = "oneshot";
          # Do I need to use nix-collect-garbage at all?
          # ExecStart = "/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-old";
          # todo Use pkgs.nix here?
          ExecStart = "${pkgs.nix}/bin/nix store gc";
          # ExecStart = "/nix/var/nix/profiles/default/bin/nix store gc";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      "update-flatpaks" = {
        Unit = {
          Description = "Update Flatpaks";
          # After = [ "network-online.target" ];
          # Requires = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.flatpak}/bin/flatpak update --assumeyes --noninteractive";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
    sessionVariables = {
      # gcr
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
      # Sway
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
    startServices = "sd-switch";
    timers = {
      "nix-garbage-collection" = {
        Unit = {
          Description = "Initiate Nix garbage collection weekly";
        };

        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
      # todo Service / Timer to auto-update Nix?
      "update-flatpaks" = {
        Unit = {
          Description = "Update Flatpaks daily";
        };

        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };

    tmpfiles.rules = [
      "d ${homeDirectory}/Books 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Books/Audiobooks 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Books/Books 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Projects 0750 ${username} ${username} - -"
      "L+ ${config.xdg.configHome}/ssh - - - - ${homeDirectory}/.ssh"
      "L+ ${config.xdg.configHome}/gnupg - - - - ${homeDirectory}/.gnupg"
      "L+ ${homeDirectory}/Documents - - - - ${homeDirectory}/Nextcloud/Documents"
      "L+ ${homeDirectory}/Notes - - - - ${homeDirectory}/Nextcloud/Notes"
    ];
  };

  xdg.portal = {
    config = {
      common = {
        default = [ "gtk" ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        # "org.freedesktop.portal.FileChooser" = ["xdg-desktop-portal-gtk"];
      };
    };
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    xdgOpenUsePortal = true;
  };
  # xdg.enable = true; ?
  # xdg.userDirs.createDirectories = true;

  # todo Look into using these options.

  # accounts.email.accounts.<name>.thunderbird.enable

  # home.keyboard
  # home.language
  # home.language.measurement

  # wayland.windowManager.sway.enable
  # wayland.windowManager.sway.config
}
