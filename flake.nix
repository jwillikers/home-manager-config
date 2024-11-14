{
  description = "Home Manager configuration of jwillikers";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      # todo use release branch?
      url = "github:nix-community/home-manager";
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
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      # nix-flatpak,
      nix-update-scripts,
      nixgl,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ nixgl.overlay ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
        pre-commit = pre-commit-hooks.lib.${system}.run (
          import ./pre-commit-hooks.nix { inherit pkgs treefmtEval; }
        );
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        packages = import ./packages { inherit pkgs; };
        homeConfigurations."jordan" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            ./scripts
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
          };
        };
      in
      with pkgs;
      {
        apps = {
          inherit (nix-update-scripts.apps.${system}) update-nix-direnv;
          inherit (nix-update-scripts.apps.${system}) update-nixos-release;
          update-packages =
            let
              script = pkgs.writeShellApplication {
                name = "update-packages";
                text = ''
                  set -eou pipefail
                  ${builtins.concatStringsSep "\n" (
                    builtins.map (
                      package: "${pkgs.nix-update}/bin/nix-update ${package} --build --flake --version branch"
                    ) (builtins.attrNames packages)
                  )}
                  ${treefmtEval.config.build.wrapper}/bin/treefmt
                '';
              };
            in
            {
              type = "app";
              program = "${script}/bin/update-packages";
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
        packages = {
          default = homeConfigurations."jordan".activationPackage;
          inherit homeConfigurations;
        } // packages;
      }
    );
}
