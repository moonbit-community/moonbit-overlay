{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;

      overlay = import ./.;

      versions = import ./versions;
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
        // { default = self.packages.${system}.moonbit-bin; }
      );
    };
}
