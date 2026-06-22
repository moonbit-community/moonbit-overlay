# Smoke test for the fine-grained builders: compile + link a trivial main package
# straight through buildMoonCore / linkMoonCore, no `moon`/mymoon involved.
#   nix build -f test-fine-grained.nix --impure --print-out-paths
let
  pkgs = import <nixpkgs> { };
  system = pkgs.stdenv.hostPlatform.system;
  toolchain =
    (builtins.getFlake "github:moonbit-community/moonbit-overlay").packages.${system}.moonbit_latest;
  buildMoonbitPackage = import ./lib/moonPlatform/buildMoonbitPackage.nix { inherit (pkgs) lib stdenv; };
  linkMoonbitProgram = import ./lib/moonPlatform/linkMoonbitProgram.nix { inherit (pkgs) lib stdenv; };

  src = pkgs.writeTextDir "main.mbt" ''
    fn main {
      println("hi from buildMoonbitPackage framework")
    }
  '';

  core = buildMoonbitPackage {
    pname = "hello_main";
    pkg = "hello/main";
    inherit src toolchain;
    files = [ "main.mbt" ];
    isMain = true;
  };
in
linkMoonbitProgram {
  pname = "hello_main";
  main = "hello/main";
  cores = [ { core = core; name = "hello_main"; } ];
  pkgSources = [ { pkg = "hello/main"; src = src; } ];
  inherit toolchain;
}
