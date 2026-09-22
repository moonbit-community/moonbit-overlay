{
  description = "Versioned binary MoonBit toolchains";

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
      forEachSystem = lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      packagesFor = pkgs: import ./lib/moonbit-bin.nix { inherit pkgs; };
      treefmtEval = forEachSystem (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      overlays.default = import ./default.nix;
      packages = forEachSystem (
        system:
        let
          packages = packagesFor nixpkgs.legacyPackages.${system};
        in
        packages // lib.optionalAttrs (packages ? latest) { default = packages.latest; }
      );
      apps = forEachSystem (
        system:
        let
          packages = self.packages.${system};
          mkApp = name: {
            type = "app";
            program = lib.getExe' packages.default name;
          };
        in
        lib.optionalAttrs (packages ? default) (
          lib.genAttrs [
            "moon"
            "moonx"
            "moonc"
            "mooncake"
            "moon_cove_report"
            "moondoc"
            "moonfmt"
            "mooninfo"
            "moonrun"
          ] mkApp
          // {
            default = mkApp "moon";
          }
        )
      );
      templates.default = {
        path = ./moonbit-dev;
        description = "A MoonBit development shell";
      };
      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);
      checks = forEachSystem (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
