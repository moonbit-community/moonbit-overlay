# Smoke test for the fine-grained builders: compile + link a trivial main package
# straight through buildMoonCore / linkMoonCore, no `moon`/mymoon involved.
#   nix build -f test-fine-grained.nix --impure --print-out-paths
let
  pkgs = import <nixpkgs> { };
  system = pkgs.stdenv.hostPlatform.system;
  toolchain =
    (builtins.getFlake "github:moonbit-community/moonbit-overlay").packages.${system}.moonbit_latest;
  buildMoonCore = import ./lib/moonPlatform/buildMoonCore.nix { inherit (pkgs) lib stdenv; };
  linkMoonCore = import ./lib/moonPlatform/linkMoonCore.nix { inherit (pkgs) lib stdenv; };

  src = pkgs.writeTextDir "main.mbt" ''
    fn main {
      println("hi from buildMoonCore framework")
    }
  '';

  core = buildMoonCore {
    pname = "hello_main";
    pkg = "hello/main";
    inherit src toolchain;
    files = [ "main.mbt" ];
    isMain = true;
  };
in
linkMoonCore {
  pname = "hello_main";
  main = "hello/main";
  cores = [ { core = core; name = "hello_main"; } ];
  pkgSources = [ { pkg = "hello/main"; src = src; } ];
  inherit toolchain;
}
