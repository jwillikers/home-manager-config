{
  description = "Home Manager configuration of jwillikers";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      # todo Create utility to auto-update like for the nixpkgs NixOS release branch.
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module.git?ref=release-2.91";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-update-scripts = {
      url = "github:jwillikers/nix-update-scripts";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # todo nix-index-database
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    # todo inputs follows for sops?
    # sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      # deadnix: skip
      self,
      flake-utils,
      home-manager,
      lix-module,
      # nix-flatpak,
      nix-index-database,
      nix-update-scripts,
      nixgl,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          lix-module.overlays.default
          nixgl.overlay
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          # todo Limit this to specific packages.
          config.allowUnfree = true;
        };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit pkgs treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        packages = import ./packages { inherit pkgs; };
        homeConfigurations."jordan@precision" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            ./scripts
            nix-index-database.hmModules.nix-index
            # todo Use nix-flatpak with NixOS.
            # I'd rather install Flatpaks system-wide.
            # nix-flatpak.homeManagerModules.nix-flatpak
            # sops-nix.homeManagerModules.sops
          ];

          # sharedModules = [
          # sops-nix.homeManagerModules.sops
          # ];

          extraSpecialArgs = {
            inherit inputs nixgl packages;
            desktop = "sway";
            username = "jordan";
          };
        };
        homeConfigurations."jordan@x1-yoga" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            ./scripts
            nix-index-database.hmModules.nix-index
            # todo Use nix-flatpak with NixOS.
            # I'd rather install Flatpaks system-wide.
            # nix-flatpak.homeManagerModules.nix-flatpak
            # sops-nix.homeManagerModules.sops
          ];

          # sharedModules = [
          # sops-nix.homeManagerModules.sops
          # ];

          extraSpecialArgs = {
            inherit inputs nixgl packages;
            desktop = "kde";
            username = "jordan";
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
                  ) (builtins.attrNames packages)
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
          default = homeConfigurations."jordan@precision".activationPackage;
          inherit homeConfigurations;
        } // packages;
      }
    );
}
