{
  description = "A MoonBit development shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
  };
  outputs =
    { nixpkgs, moonbit-overlay, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ moonbit-overlay.overlays.default ];
          };
        in
        {
          default = pkgs.mkShell { packages = [ pkgs.moonbit-bin.latest ]; };
        }
      );
    };
}
