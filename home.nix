{
  config,
  hostname,
  inputs,
  lib,
  nixgl,
  packages,
  pkgs,
  username,
  ...
}:
let
  flatpaks = [
    "com.bitwarden.desktop" # Password vault
    "com.discordapp.Discord" # Chat and meetings
    "com.github.Anuken.Mindustry" # Factorio-like tower defense game
    "com.github.bvschaik.julius" # A fully functional open-source adaptation of Caesar III
    "com.github.geigi.cozy" # Audiobook player
    "com.github.iwalton3.jellyfin-media-player" # Media server client
    "com.github.keriew.augustus" # Open source re-implementation of the Caesar III game engine with changes to gameplay
    "com.github.tchx84.Flatseal" # Flatpak permissions manager
    "com.heroicgameslauncher.hgl" # Heroic Games Launcher
    "com.nextcloud.desktopclient.nextcloud" # File sync service
    "com.play0ad.zeroad" # 0 A.D. is a real-time strategy (RTS) game of ancient warfare, like Age of Empires II
    "com.usebottles.bottles"
    "org.freedesktop.Platform.VulkanLayer.gamescope//23.08" # For Heroic Games Launcher
    "org.freedesktop.Platform.VulkanLayer.gamescope//24.08" # For Bottles
    "org.freedesktop.Platform.VulkanLayer.gamescope//25.08"
    "org.freedesktop.Platform.VulkanLayer.MangoHud//24.08" # For Bottles
    "org.freedesktop.Platform.VulkanLayer.MangoHud//25.08"
    "org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08"
    "org.openjkdf2.OpenJKDF2" # Open source Jedi Knight Dark Forces 2 engine
    "de.haeckerfelix.Fragments" # Torrent downloader
    "im.riot.Riot" # Chat
    # todo Use Nix KCC in 25.11
    "io.gitlab.azymohliad.WatchMate" # PineTime watch utility
    "io.github.ciromattia.kcc" # Kindle Comic Converter
    "io.gitlab.news_flash.NewsFlash" # News feed reader
    "io.github.theforceengine.tfe" # The Force Engine
    "net.davidotek.pupgui2" # ProtonUp-Qt installs Wine and Proton compatibility tools
    "net.werwolv.ImHex" # Hex editor
    "net.veloren.airshipper" # Launcher for Veloren RPG
    "org.fedoraproject.MediaWriter" # USB writer
    # "org.fritzing.Fritzing"
    "org.gnome.Maps" # Maps
    # "org.gnome.Calendar"
    # "org.gnome.Contacts"
    # "org.gnome.Lollypop"
    # "org.gnome.Podcasts"
    # "org.gnome.Seahorse"
    # "org.gnome.Todo"
    "org.gtk.Gtk3theme.Adwaita-dark" # Flatpak icon theme
    "org.kde.itinerary" # Travel planner
    "org.kde.krita" # Drawing tool
    # "org.keepassxc.KeePassXC"
    "org.libreoffice.LibreOffice" # Office software suite
    "org.luanti.luanti" # Block-based sandbox game platform, like Minecraft
    "org.mozilla.Thunderbird" # Email client
    "org.raspberrypi.rpi-imager" # Raspberry Pi imaging tool
    "org.thonny.Thonny" # Python IDE
    "org.torproject.torbrowser-launcher" # Anonymous browser
    "one.flipperzero.qFlipper" # FlipperZero desktop application
    "page.kramo.Sly"
    "us.zoom.Zoom" # Meetings
  ];
  udevPackages = [
    pkgs.nrf-udev
    pkgs.picoprobe-udev-rules
    pkgs.qFlipper
    pkgs.steam-unwrapped
    packages.udev-rules
  ]
  ++ lib.optionals (hostname == "steamdeck") [
    packages.steam-deck-auto-disable-steam-controller
  ];
in
{

  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Modules exported from other flakes:
    inputs.media-juggler.homeModules.media-juggler
    inputs.nix-index-database.homeModules.nix-index
    # inputs.sops-nix.homeManagerModules.sops
    ./_mixins
  ];

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

  home = {
    inherit username;

    homeDirectory = "/home/${username}";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.

    packages = with pkgs; [
      chapterz # MusicBrainz utility for audiobook chapters
      minuimus # Lossless file minimizer
      pdfsizeopt # Lossless PDF size optimizer
      advancecomp # Compression utilities
      age # Cryptography utility
      android-tools # Tools for Android mobile OS
      appstream
      # librsvg?
      asciidoctor
      # beets # Music collection organizer
      # (config.lib.nixGL.wrap calibre) # EBook manager
      efficient-compression-tool # Image optimization tool
      eslint # JavaScript linter
      calibre # EBook manager
      cbconvert # Comic book converter
      ccache # Compiler cache
      chromaprint # Utility to calculate AcoustID audio fingerprint
      (config.lib.nixGL.wrap chromium) # Web browser
      clipse # Clipboard manager
      deadnix # Nix dead code finder
      deploy-rs # Nix deployment
      flatpak-builder # Build Flatpaks
      ghc # Glasgow Haskell Compiler
      # gptfdisk
      # h # Modern Unix autojump for git projects
      julia # Julia programming language
      just # Command runner
      image_optim # Image optimizer
      kakasi # Japanese Kanji to Kana converter
      libtree # Tree output for ldd
      m4b-tool # Audiobook merging, splitting, and chapters tool
      minio-client # S3-compatible object storage client
      (config.lib.nixGL.wrap mumble) # Voice chat
      mupdf-headless # PDF utility
      net-snmp # SNMP manager tools
      nil # Nix language engine for IDEs
      nixfmt-rfc-style # Nix code formatter
      # todo Set GITHUB_TOKEN in environment for pull-request reviews.
      nixpkgs-review # Nix code review
      nix-tree # Examine dependencies of Nix derivations
      nix-update # Update Nix packages
      nodejs_24 # Node Javascript
      # vue-language-server
      nu_scripts # Nushell scripts
      nurl # Nix URL fetcher
      picard # Music tagger
      pipx # Python executable installer
      pre-commit # Git pre-commit hooks manager
      probe-rs # Debug probe tool
      python3Packages.python # Python
      rpiboot # Raspberry Pi bootloader utility
      rustup # Rust toolchain installer
      # qemu # Emulator
      # quickemu # Quickly spin up virtual machines
      sops # Secret management
      ssh-to-age # Convert SSH keys to age keys
      (config.lib.nixGL.wrap github-desktop) # Git GUI
      (config.lib.nixGL.wrap sublime-merge) # Git GUI
      tailscale # WireGuard-based VPN
      tesseract # OCR tool
      tio # Serial device I/O tool
      tone # Audiobook metadata tool
      treefmt # Code formatter
      # todo Use wl-clipboard-rs?
      wl-clipboard # Wayland clipboard program
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
      escalationProgram = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        escalation_program=/usr/bin/sudo
        if [ -x "/usr/bin/doas" ]; then
          escalation_program=/usr/bin/doas
        fi
      '';
      udev =
        lib.hm.dag.entryAfter
          [
            "escalationProgram"
            "writeBoundary"
          ]
          ''
            for package in ${builtins.concatStringsSep " " (lib.unique (map toString udevPackages))}; do
              for file in $(shopt -s nullglob dotglob; echo $package/{etc,lib}/udev/rules.d/*); do
                target_file=/etc/udev/rules.d/$(basename $file)
                if ! cmp --silent $file $target_file; then
                  run "$escalation_program" install -D --mode=0644 --target-directory=/etc/udev/rules.d $file
                fi
              done
            done
          '';
      flathub =
        lib.hm.dag.entryAfter
          [
            "escalationProgram"
            "writeBoundary"
          ]
          ''
            if ! ${pkgs.flatpak}/bin/flatpak remotes --columns=name --system \
              | grep --fixed-strings --line-regexp --quiet 'flathub'; then
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system $VERBOSE_ARG \
                flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            fi
          '';
      flatpaks =
        lib.hm.dag.entryAfter
          [
            "escalationProgram"
            "flathub"
            "writeBoundary"
          ]
          (
            ''
              installed_flatpaks=$(${pkgs.flatpak}/bin/flatpak list --columns=application --system)
            ''
            + builtins.concatStringsSep "\n" (
              builtins.map (flatpak: ''
                if ! echo "$installed_flatpaks" | grep --fixed-strings --line-regexp --quiet '${flatpak}'; then
                  run "$escalation_program" ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG install --noninteractive \
                  --system flathub '${flatpak}'
                fi
              '') flatpaks
            )
            + ''
              # Override permissions for Bottles to access the Steam installation.
              # todo Only run this if the Bottles flatpak is being installed and the Steam package is being installed.
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG override --system com.usebottles.bottles --filesystem=xdg-data/Steam
              # Override permissions for Heroic Games Launcher to permit access to Ludusavi.
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak $VERBOSE_ARG override --system com.heroicgameslauncher.hgl \
                --filesystem='~/.config/ludusavi' \
                --filesystem='~/.config/rclone:ro' \
                --filesystem='~/.nix-profile/bin/heroic-ludusavi-wrapper.sh' \
                --filesystem='~/ludusavi-backup' \
                --filesystem=/nix/store
            ''
          );
      flatpakTheme =
        lib.hm.dag.entryAfter
          [
            "escalationProgram"
            "flatpaks"
            "dconfSettings"
            "writeBoundary"
          ]
          ''
            COLOR_SCHEME=$(${lib.getExe pkgs.dconf} read /org/gnome/desktop/interface/color-scheme | sed -e "s/'//g")
            GTK_THEME=$(${lib.getExe pkgs.dconf} read /org/gnome/desktop/interface/gtk-theme | sed -e "s/'//g")
            ICON_THEME=$(${lib.getExe pkgs.dconf} read /org/gnome/desktop/interface/icon-theme | sed -e "s/'//g")
            XCURSOR_THEME=$(${lib.getExe pkgs.dconf} read /org/gnome/desktop/interface/cursor-theme | sed -e "s/'//g")
            if [ "$COLOR_SCHEME" == "prefer-dark" ]; then
              GTK_THEME="$GTK_THEME:dark"
            fi
            flatpak_overrides=$(${pkgs.flatpak}/bin/flatpak override --show --system)
            FLATPAK_GTK_THEME=$(echo "$flatpak_overrides" | ${lib.getExe pkgs.nawk} -F'=' '/GTK_THEME/ {print $2;}')
            FLATPAK_ICON_THEME=$(echo "$flatpak_overrides" | ${lib.getExe pkgs.nawk} -F'=' '/ICON_THEME/ {print $2;}')
            FLATPAK_XCURSOR_THEME=$(echo "$flatpak_overrides" \
              | ${lib.getExe pkgs.nawk} -F'=' '/XCURSOR_THEME/ {print $2;}')
            if [ "$FLATPAK_GTK_THEME" != "$GTK_THEME" ]; then
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak override --env=GTK_THEME="$GTK_THEME"
            fi
            if [ "$FLATPAK_ICON_THEME" != "$ICON_THEME" ]; then
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak override --env=ICON_THEME="$ICON_THEME"
            fi
            if [ "$FLATPAK_XCURSOR_THEME" != "$XCURSOR_THEME" ]; then
              run "$escalation_program" ${pkgs.flatpak}/bin/flatpak override --env=XCURSOR_THEME="$XCURSOR_THEME"
            fi
          '';
    };

    file = {
      "${config.xdg.configHome}/foot/foot.ini".source = packages.foot-config + "/etc/foot/foot.ini";
      "${config.xdg.configHome}/sublime-merge/Packages/User".source =
        packages.sublime-merge-config + "/etc/sublime-merge/Packages/User";
      "${config.xdg.configHome}/tio/config".source = packages.tio-config + "/etc/tio/config";
      "${config.xdg.configHome}/vim/vimrc".source = packages.vim-config + "/etc/vim/vimrc";
      ".gnupg/common.conf".text = "use-keyboxd";
      ".ssh/config.d".source = packages.openssh-client-config + "/etc/ssh/ssh_config.d";

      # todo Comicvine API key for Calibre plugin from SOPS
      # ".var/app/com.calibre_ebook.calibre/config/calibre/plugins/comicvine.json".contents = ''
      # {
      #   "api_key": "<API KEY>",
      #   "max_volumes": 2,
      #   "requests_rate": 1,
      #   "worker_threads": 16
      # }
      # '';
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-lua
        kdePackages.fcitx5-configtool
        kdePackages.fcitx5-qt
        libsForQt5.fcitx5-qt
      ];
      inherit (pkgs.kdePackages) fcitx5-with-addons;
      waylandFrontend = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # package = pkgs.nixVersions.latest;
    # package = inputs.lix-module.packages.${pkgs.system}.default;
    package = pkgs.lix;
    # A lot of these should instead to be managed system-wide, right?
    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      # Don't use the temp directory as that requires a lot of RAM.
      build-dir = "/var/tmp/nix-daemon";
      max-jobs = 1;
      # On x86_64 for emulation.
      # todo: Set this only if/then.
      extra-platforms = "aarch64-linux";
      extra-sandbox-paths = [ "/nix/var/cache/ccache" ];
      extra-trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
      # extra-trusted-substituters = [ "https://cache.lix.systems" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "${username}"
      ];
      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
      warn-dirty = false;
    };
  };

  nixGL = {
    installScripts = [
      "mesa"
      "mesaPrime"
    ];
    inherit (nixgl) packages;
    vulkan.enable = true;
  };

  # nixpkgs.overlays = [
  # inputs.media-juggler.overlays.calibre-acsm-plugin-libcrypto
  # inputs.lix-module.overlays.default
  # ];

  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Solarized (dark)";
      };
    };
    beets = {
      enable = true;
      package = pkgs.unstable.beets;
      # todo Add API keys when SOPS support is added.
      settings = {
        plugins = [
          "chroma"
          "embedart"
          "export"
          "fetchart"
          "keyfinder"
          "lyrics"
          "scrub"
        ];
        acoustid = {
          # apikey = "";
        };
        embedart = {
          remove_art_file = true;
        };
        fetchart = {
          # fanarttv_key = "";
          # google_key = "";
          high_resolution = true;
          # lastfm_key = "";
        };
        keyfinder = {
          bin = "keyfinder-cli";
        };
        lyrics = {
          # bing_client_secret = "";
          # bing_lang_to = "english";
          # google_API_key = "";
          synced = true;
        };
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
          editor = "${lib.getExe pkgs.vscode} --wait";
          pager = "${lib.getExe pkgs.delta}";
        };
        credential.helper = "${lib.getBin pkgs.gitFull}/bin/git-credential-libsecret";
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
          # todo
          # tool = "${lib.getExe pkgs.sublime-merge}";
          tool = "${lib.getBin pkgs.sublime-merge}/bin/smerge";
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
    gpg.enable = true;
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    nix-index-database.comma.enable = true;
    nushell = {
      enable = true;
      # todo Use in 25.05
      # plugins = with pkgs.nushellPlugins; [
      #   formats
      #   query
      #   units
      # ];
    };
    rclone = {
      enable = true;
      remotes = {
        "nextcloud" = {
          config = {
            type = "webdav";
            url = "https://cloud.jwillikers.io/remote.php/dav/files/${username}/";
            user = username;
            vendor = "nextcloud";
          };
          secrets = {
            pass = config.sops.secrets."${hostname}/nextcloud-ludusavi".path;
          };
        };
      };
      # Ensure that sops-nix is activated before the Rclone configuration, since it requires the secret to be available.
      writeAfter = "reloadSystemd";
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
      profiles.default.extensions = with pkgs.vscode-extensions; [
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
    };
  };

  systemd.user = {
    services = {
      #      "nix-garbage-collection" = {
      #        Unit = {
      #          Description = "Initiate Nix garbage collection";
      #        };
      #
      #        Service = {
      #          Type = "oneshot";
      #          ExecStart = "${pkgs.nix}/bin/nix store gc";
      #        };
      #      };
      "update-flatpaks" = {
        Unit = {
          Description = "Update Flatpaks";
          # After = [ "network-online.target" ];
          # Requires = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          # ExecStart = "${lib.getExe pkgs.flatpak} update --assumeyes --noninteractive";
          ExecStart = "/usr/bin/flatpak update --assumeyes --noninteractive";
        };
      };
    };
    startServices = "sd-switch";
    timers = {
      #      "nix-garbage-collection" = {
      #        Unit = {
      #          Description = "Initiate Nix garbage collection weekly";
      #        };
      #
      #        Timer = {
      #          OnCalendar = "yearly";
      #          Persistent = true;
      #        };
      #
      #        Install = {
      #          WantedBy = [ "timers.target" ];
      #        };
      #      };
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
      # Create age keys directory for SOPS.
      "d ${config.xdg.configHome}/sops/age 0750 ${username} ${username} - -"
      "d ${config.home.homeDirectory}/Books 0750 ${username} ${username} - -"
      "d ${config.home.homeDirectory}/Books/Audiobooks 0750 ${username} ${username} - -"
      "d ${config.home.homeDirectory}/Books/Books 0750 ${username} ${username} - -"
      "d ${config.home.homeDirectory}/Games 0750 ${username} ${username} - -"
      # "v ${homeDirectory}/Games/gog 0750 ${username} ${username} - -"
      "d ${config.home.homeDirectory}/Projects 0750 ${username} ${username} - -"
      "L+ ${config.xdg.configHome}/ssh - - - - ${config.home.homeDirectory}/.ssh"
      "L+ ${config.xdg.configHome}/gnupg - - - - ${config.home.homeDirectory}/.gnupg"
      # Symlink ~/.gitconfig to ~/.config/git due to GUI tools relying on it being there.
      "L+ ${config.home.homeDirectory}/.gitconfig - - - - ${config.xdg.configHome}/git/config"
    ]
    ++ lib.optionals (hostname != "steamdeck") [
      "L+ ${config.home.homeDirectory}/Documents - - - - ${config.home.homeDirectory}/Nextcloud/Documents"
      "L+ ${config.home.homeDirectory}/Notes - - - - ${config.home.homeDirectory}/Nextcloud/Notes"

    ];
  };

  xdg = {
    userDirs.createDirectories = lib.mkDefault true;
    enable = true;
    portal.xdgOpenUsePortal = true;
  };

  # todo Look into using these options.
  # accounts.email.accounts.<name>.thunderbird.enable
  # home.keyboard
  # home.language
  # home.language.measurement
}
