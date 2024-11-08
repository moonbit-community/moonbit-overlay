{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    core = {
      url = "github:moonbitlang/core";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, core }:
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
            };
        });

      versions = import ./versions.nix lib;
      mkMoonbitBin = pkgs: import ./lib/moonbit-bin.nix {
        inherit lib pkgs versions;
        coreSrc = core;
      };
    in
    {
      overlays = {
        default = overlay;
        moonbit-overlay = overlay;
      };

      packages = forEachSystem (system:
        mkMoonbitBin nixpkgs.legacyPackages.${system}
        // { default = self.packages.${system}.moonbit.latest; }
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
    };
}
