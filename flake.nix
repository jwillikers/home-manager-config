{
  description = "Home Manager configuration of jwillikers";

  inputs = {
    chapterz = {
      url = "github:jwillikers/chapterz";
      inputs = {
        flake-utils.follows = "flake-utils";
        nix-update-scripts.follows = "nix-update-scripts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    m4b-tool = {
      url = "github:sandreas/m4b-tool";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    media-juggler = {
      url = "github:jwillikers/media-juggler";
      inputs = {
        flake-utils.follows = "flake-utils";
        m4b-tool.follows = "m4b-tool";
        nix-update-scripts.follows = "nix-update-scripts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nix-update-scripts = {
      url = "github:jwillikers/nix-update-scripts";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+ssh://git@forgejo.jwillikers.io/jwillikers/nix-secrets.git?shallow=1";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # Add nixpkgs-unstable here so that it is part of the generated registries.json file
    nixpkgs-unstable.url = "github:NixOS/nixpkgs";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      # deadnix: skip
      self,
      # deadnix: skip
      chapterz,
      flake-utils,
      home-manager,
      lix-module,
      # deadnix: skip
      m4b-tool,
      # deadnix: skip
      media-juggler,
      # deadnix: skip
      nix-index-database,
      # deadnix: skip
      nix-secrets,
      nix-update-scripts,
      nixgl,
      nixpkgs,
      # deadnix: skip
      nixpkgs-unstable,
      pre-commit-hooks,
      # deadnix: skip
      sops-nix,
      treefmt-nix,
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = import ./overlays { inherit inputs; };
        overlaysList = [
          lix-module.overlays.default
          chapterz.overlays.chapterz
          m4b-tool.overlay
          nixgl.overlay
          overlays.gcr
          overlays.ludusavi-rclone
          # overlays.packages
        ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlaysList;
          # todo Limit this to specific packages.
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "python-2.7.18.8" ];
          };
        };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit pkgs treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        packages = import ./packages { inherit pkgs; };
        homeConfigurations = {
          "jordan@precision5350" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              ./home.nix
            ];

            extraSpecialArgs = {
              inherit inputs nixgl packages;
              desktop = "hyprland";
              hostname = "precision5350";
              username = "jordan";
            };
          };
          "deck@steamdeck" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              ./home.nix
            ];

            extraSpecialArgs = {
              inherit inputs nixgl packages;
              desktop = "kde";
              hostname = "steamdeck";
              username = "deck";
            };
          };
          "jordan@x1-yoga" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              ./home.nix
            ];

            extraSpecialArgs = {
              inherit inputs nixgl packages;
              desktop = "kde";
              hostname = "x1-yoga";
              username = "jordan";
            };
          };
        };
      in
      with pkgs;
      {
        apps = {
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv update-nixos-release;
          update-packages = {
            type = "app";
            program = builtins.toString (
              pkgs.writers.writeNu "update-packages" ''
                ${builtins.concatStringsSep "\n" (
                  builtins.map (
                    package: "${pkgs.lib.getExe pkgs.nix-update} ${package} --build --flake --version branch"
                  ) (builtins.attrNames (removeAttrs packages [ "udev-rules" ]))
                )}
                ${pkgs.lib.getExe treefmtEval.config.build.wrapper}
              ''
            );
          };
        };
        devShells.default = mkShell {
          inherit (pre-commit) shellHook;
          nativeBuildInputs =
            with pkgs;
            [
              asciidoctor
              just
              pkgs.home-manager
              lychee
              nushell
              treefmtEval.config.build.wrapper
              (builtins.attrValues treefmtEval.config.build.programs)
            ]
            ++ pre-commit.enabledPackages;
        };
        formatter = treefmtEval.config.build.wrapper;
        # inherit packages;
        packages = {
          default = homeConfigurations."jordan@5350precision".activationPackage;
          inherit homeConfigurations;
        }
        // packages;
      }
    );
}
