{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;

      lsp = lib.warn ''
        moonbit-overlay: 'lsp' is deprecated and has been removed.
        The moonbit-bin.moonbit.$${version} package already includes moonbit-lsp.
        For more information, see: https://github.com/moonbit-community/moonbit-overlay/pull/14
      '' null;

      overlay = (
        final: prev:
        let
          inherit (final) lib;
        in
        rec {
          moonbit-bin =
            (prev.moonbit-bin or { })
            // import ./lib/moonbit-bin.nix {
              inherit lib;
              pkgs = final;
              versions = import ./versions.nix lib;
            }
            // {
              inherit lsp;
            };
          moonbit-lang = final.callPackage ./lib/compiler.nix { };

          mkMoonPlatform = final.callPackage ./lib/moonPlatform {
            versions = import ./versions.nix lib;
          };
          moonPlatform = mkMoonPlatform { version = "latest"; };
          versions = import ./versions.nix lib;
        }
      );

      versions = import ./versions.nix lib;
      mkMoonbitBin =
        pkgs:
        import ./lib/moonbit-bin.nix {
          inherit lib pkgs versions;
        };

      treefmtEval = forEachSystem (
        system: treefmt-nix.lib.evalModule (nixpkgs.legacyPackages.${system}) ./treefmt.nix
      );
    in
    {
      overlays = {
        default = overlay;
        moonbit-overlay = overlay;
      };

      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        mkMoonbitBin pkgs
        // {
          default = self.packages.${system}.moonbit.latest;
        }
        // {
          inherit lsp;
        }
        // {
          # compiler build from source
          # not used now
          compiler = pkgs.callPackage ./lib/compiler.nix { };
        }
      );

      apps = forEachSystem (
        system:
        let
          getMoonbit = lib.getExe' self.packages.${system}.default;
          mkMoonbitApp = name: {
            type = "app";
            program = getMoonbit name;
          };
        in
        {
          default = self.apps.${system}.moon;
        }
        // (lib.genAttrs [
          "moon"
          "moonc"
          "mooncake"
          "moon_cove_report"
          "moondoc"
          "moonfmt"
          "mooninfo"
          "moonrrun"
          "moonbit-lsp"
        ] mkMoonbitApp)
      );

      templates = rec {
        default = moonbit-dev;
        moonbit-dev = {
          path = ./moonbit-dev;
          description = "A startup basic MoonBit project";
        };
      };

      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);
      checks = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;
          # Run `nix build "#checks.<system>.testBuildMoonPackage"`
          testBuildMoonPackage = pkgs.moonPlatform.buildMoonPackage {
            name = "moonbit-overlay-test-with-deps";
            src = ./test/with_deps;
            moonModJson = ./test/with_deps/moon.mod.json;
            moonRegistryIndex = pkgs.fetchgit {
              url = "https://mooncakes.io/git/index";
              rev = "db98c15d651555a82a229a8ed29973ef04a3c683";
              sha256 = "sha256-ZU514Qu8/aJJLRvnVOH+qc8SN1vAoFV338UQvIxh+Ro=";
            };
          };
        }
      );
    };
}
