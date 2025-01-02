{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    core = {
      url = "github:moonbitlang/core";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, core, treefmt-nix }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;

      overlay = (final: prev:
        let
          inherit (final) lib;
        in
        {
          moonbit-bin = (prev.moonbit-bin or { }) //
            import ./lib/moonbit-bin.nix {
              inherit lib;
              pkgs = final;
              versions = import ./versions.nix lib;
              coreSrc = core;
            } //
            import ./lib/lsp.nix {
              inherit lib;
              inherit (final) moonbit-bin;
              pkgs = final;
            };
          moonbit-lang = final.callPackage ./lib/compiler.nix { };
        });

      versions = import ./versions.nix lib;
      mkMoonbitBin = pkgs: import ./lib/moonbit-bin.nix {
        inherit lib pkgs versions;
        coreSrc = core;
      };
      mkMoonbitLsp = pkgs: moonbit-bin: import ./lib/lsp.nix {
        inherit lib pkgs moonbit-bin;
      };

      treefmtEval = forEachSystem (system:
        treefmt-nix.lib.evalModule (nixpkgs.legacyPackages.${system}) ./treefmt.nix
      );
    in
    {
      overlays = {
        default = overlay;
        moonbit-overlay = overlay;
      };

      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        mkMoonbitBin pkgs
        // { default = self.packages.${system}.moonbit.latest; }
        // mkMoonbitLsp pkgs self.packages.${system}
        // {
          compiler = pkgs.callPackage ./lib/compiler.nix { };
        }
      );

      apps = forEachSystem (system:
        let
          getMoonbit = lib.getExe' self.packages.${system}.default;
          mkMoonbitApp = name: {
            type = "app";
            program = getMoonbit name;
          };
        in
        {
          default = self.apps.${system}.moon;
        } // (lib.genAttrs [
          "moon"
          "moonc"
          "mooncake"
          "moon_cove_report"
          "moondoc"
          "moonfmt"
          "mooninfo"
          "moonrrun"
        ]
          mkMoonbitApp));

      templates = rec {
        default = moonbit-dev;
        moonbit-dev = {
          path = ./moonbit-dev;
          description = "A startup basic MoonBit project";
        };
      };

      formatter = forEachSystem (system:
        treefmtEval.${system}.config.build.wrapper
      );
    };
}
