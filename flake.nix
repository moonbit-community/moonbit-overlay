{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;

      overlay = import ./.;

      versions = import ./versions lib.importJSON;
      mkMoonbitBin = pkgs: import ./lib/moonbit-bin.nix {
        inherit lib pkgs versions;
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
