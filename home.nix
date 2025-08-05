{
  config,
  desktop,
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
  homeDirectory = "/home/${username}";
  flatpaks = [
    "com.bitwarden.desktop"
    # "com.calibre_ebook.calibre"
    "com.discordapp.Discord"
    "com.github.geigi.cozy"
    "com.github.iwalton3.jellyfin-media-player"
    "com.github.tchx84.Flatseal"
    "com.nextcloud.desktopclient.nextcloud"
    "de.haeckerfelix.Fragments"
    "im.riot.Riot"
    "io.github.ciromattia.kcc"
    "io.gitlab.azymohliad.WatchMate"
    "io.gitlab.news_flash.NewsFlash"
    # "net.hovancik.Stretchly"
    # "net.lutris.Lutris"
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
    "one.flipperzero.qFlipper"
    "page.kramo.Sly"
    "us.zoom.Zoom"
    # "com.valve.Steam"
  ];
  udevPackages = [
    pkgs.nrf-udev
    pkgs.picoprobe-udev-rules
    pkgs.qFlipper
    pkgs.steam-unwrapped
    packages.udev-rules
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
    # ./_mixins/desktop
    # ./_mixins/scripts
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
      nerd-fonts.noto
      chapterz
      minuimus
      pdfsizeopt
      advancecomp
      age
      android-tools # Tools for Android mobile OS
      appstream
      # librsvg?
      asciidoctor
      # beets # Music collection organizer
      # (config.lib.nixGL.wrap calibre) # EBook manager
      efficient-compression-tool # Image optimization tool
      calibre # EBook manager
      cbconvert # Comic book converter
      ccache # Compiler cache
      chromaprint # Utility to calculate AcoustID audio fingerprint
      clipse # Clipboard manager
      deadnix # Nix dead code finder
      deploy-rs # Nix deployment
      flatpak-builder # Build Flatpaks
      ghc # Glasgow Haskell Compiler
      gcr # A library for accessing key stores
      # gptfdisk
      # h # Modern Unix autojump for git projects
      julia # Julia programming language
      just # Command runner
      image_optim # Image optimizer
      kakasi # Japanese Kanji to Kana converter
      libtree # Tree output for ldd
      (config.lib.nixGL.wrap ludusavi) # Game save data backup tool
      (config.lib.nixGL.wrap lutris) # Game launcher
      m4b-tool # Audiobook merging, splitting, and chapters tool
      minio-client
      mupdf-headless
      net-snmp # SNMP manager tools
      nil # Nix language engine for IDEs
      nixfmt-rfc-style # Nix code formatter
      # todo Set GITHUB_TOKEN in environment for pull-request reviews.
      nixpkgs-review # Nix code review
      nix-tree # Examine dependencies of Nix derivations
      nix-update # Update Nix packages
      nu_scripts # Nushell scripts
      nurl # Nix URL fetcher
      picard # Music tagger
      pipx
      pre-commit # Git pre-commit hooks manager
      probe-rs # Debug probe tool
      python3Packages.python # Python
      rpiboot
      rustup # Rust toolchain installer
      # qemu # Emulator
      # quickemu # Quickly spin up virtual machines
      sops # Secret management
      ssh-to-age # Convert SSH keys to age keys
      (config.lib.nixGL.wrap github-desktop) # Git GUI
      (config.lib.nixGL.wrap stretchly) # Break timer
      (config.lib.nixGL.wrap sublime-merge) # Git GUI
      tailscale # WireGuard-based VPN
      tesseract
      tio # Serial device I/O tool
      tone
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

      # Symlinking the Stretchly config won't work.
      # It's also necessary to install the config when Stretchly isn't running.
      stretchly = lib.hm.dag.entryAfter [ "flatpaks" ] (
        let
          stretchly-config =
            if hostname == "steamdeck" then packages.stretchly-steam-deck-config else packages.stretchly-config;
        in
        ''
          # We don't want the cmp command to cause the script to fail.
          set +e
          cmp --silent \
            "${stretchly-config}/etc/Stretchly/config.json" \
            "${config.xdg.configHome}/Stretchly/config.json"
          exit_status=$?
          set -e
          if [ $exit_status -eq 1 ]; then
            service_running=0
            if ${lib.getBin pkgs.procps}/bin/pgrep --full --ignore-case Stretchly >/dev/null; then
              if ${lib.getBin pkgs.systemdMinimal}/bin/systemctl --user is-active stretchly.service >/dev/null; then
                service_running=1
                run ${lib.getBin pkgs.systemdMinimal}/bin/systemctl --user stop stretchly.service
              else
                run ${lib.getBin pkgs.procps}/bin/pkill --full --ignore-case Stretchly
              fi
            else
              run ${lib.getBin pkgs.util-linux}/bin/setsid ${lib.getExe pkgs.stretchly} &>/dev/null &
              run ${lib.getBin pkgs.coreutils}/bin/sleep 10
              run ${lib.getBin pkgs.procps}/bin/pkill --full --ignore-case Stretchly
            fi
            run ${lib.getBin pkgs.coreutils}/bin/sleep 1
            run mkdir --parents ${config.xdg.configHome}/Stretchly/
            run install -D --mode=0644 $VERBOSE_ARG \
                "${stretchly-config}/etc/Stretchly/config.json" \
                "${config.xdg.configHome}/Stretchly/config.json"
            if [ "$service_running" -eq 1 ]; then
              run ${pkgs.systemdMinimal}/bin/systemctl --user start stretchly.service
            else
              run ${lib.getBin pkgs.util-linux}/bin/setsid ${lib.getExe pkgs.stretchly} &>/dev/null &
            fi
          fi
        ''
      );
    };

    file = {
      "${config.xdg.configHome}/foot/foot.ini".source = packages.foot-config + "/etc/foot/foot.ini";
      # Copy the file to make it writeable.
      "${config.xdg.configHome}/ludusavi/config_source.yaml" = {
        source =
          let
            ludusavi-config =
              if hostname == "steamdeck" then packages.ludusavi-steam-deck-config else packages.ludusavi-config;
          in
          ludusavi-config + "/etc/ludusavi/config.yaml";
        onChange = ''cat ${config.xdg.configHome}/ludusavi/config_source.yaml > ${config.xdg.configHome}/ludusavi/config.yaml'';
      };
      # Copy the file to make it writeable.
      "${config.xdg.dataHome}/lutris/system_source.yml" = {
        source = packages.lutris-config + "/etc/lutris/system.yml";
        onChange = ''cat ${config.xdg.dataHome}/lutris/system_source.yml > ${config.xdg.dataHome}/lutris/system.yml'';
      };
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
      extra-trusted-substituters = [ "https://cache.lix.systems" ];
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
            url = "https://cloud.jwillikers.io/remote.php/dav/files/jordan/";
            user = "jordan";
            vendor = "nextcloud";
          };
          secrets = {
            pass = config.sops.secrets."nextcloud-ludusavi".path;
          };
        };
      };
      # Ensure that sops-nix is activated before the Rclone configuration, since it requires the secret to be available.
      writeAfter = "sops-nix";
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
      pinentry.package = if desktop == "kde" then null else pkgs.pinentry-gnome3;
    };
  };

  systemd.user = {
    services = {
      "stretchly" = {
        Unit = {
          Description = "Start Stretchly";
          After = [ "graphical-session.target" ];
          Requires = [ "graphical-session.target" ];
        };

        Service = {
          Type = "exec";
          ExecStartPre = "${lib.getBin pkgs.coreutils}/bin/sleep 1";
          # Can't use Nix's flatpak command with electron apps for reasons.
          ExecStart = "${lib.getExe pkgs.stretchly}";
          # TimeoutStopSec = 5;
          KillMode = "mixed";
          Restart = "on-failure";
          RestartSec = 10;
          ExitType = "cgroup";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
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
      "d ${homeDirectory}/Books 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Books/Audiobooks 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Books/Books 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Games 0750 ${username} ${username} - -"
      # "v ${homeDirectory}/Games/gog 0750 ${username} ${username} - -"
      "d ${homeDirectory}/Projects 0750 ${username} ${username} - -"
      "v ${homeDirectory}/ludusavi-backup 0750 ${username} ${username} - -"
      "L+ ${config.xdg.configHome}/ssh - - - - ${homeDirectory}/.ssh"
      "L+ ${config.xdg.configHome}/gnupg - - - - ${homeDirectory}/.gnupg"
      # Symlink ~/.gitconfig to ~/.config/git due to GUI tools relying on it being there.
      "L+ ${homeDirectory}/.gitconfig - - - - ${config.xdg.configHome}/git/config"
      "L+ ${homeDirectory}/Documents - - - - ${homeDirectory}/Nextcloud/Documents"
      "L+ ${homeDirectory}/Notes - - - - ${homeDirectory}/Nextcloud/Notes"
      # Symlink game save data between multiple locations.
      ## Kingdom Two Crowns
      "v ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release 0750 ${username} ${username} - -"
      "L+ ${homeDirectory}/Games/gog/kingdom-two-crowns/drive_c/users/${username}/AppData/LocalLow/noio/KingdomTwoCrowns/Release - - - - ${config.xdg.configHome}/unity3d/noio/KingdomTwoCrowns/Release"
      ## Dome Keeper
      "v '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper' 0750 ${username} ${username} - -"
      "L+ '${homeDirectory}/Games/gog/dome-keeper/drive_c/users/${username}/AppData/Roaming/Godot/app_userdata/Dome Keeper' - - - - '${config.xdg.dataHome}/godot/app_userdata/Dome Keeper'"
    ]
    ++ lib.optionals (hostname == "steamdeck") [
      # Mask broken systemd units on the Steam Deck.
      # app-firewall has a dependency problem with PyQt5
      # I have no idea why the others are broken.
      "L+ ${config.xdg.configHome}/systemd/user/app-defaultbrightness@autostart.service - - - - /dev/null"
      "L+ ${config.xdg.configHome}/systemd/user/app-firewall\\x2dapplet@autostart.service - - - - /dev/null"
      "L+ ${config.xdg.configHome}/systemd/user/app-ibus@autostart.service - - - - /dev/null"
    ];
  };

  xdg = {
    userDirs.createDirectories = lib.mkDefault true;
    enable = true;
    portal.xdgOpenUsePortal = true;
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
