# Smoke test for the native fine-grained builders: compile → link (.c) → runtime →
# cc-link into an executable, no `moon`/mymoon involved.
#   nix build -f test-native.nix --impure --print-out-paths
let
  pkgs = import <nixpkgs> { };
  system = pkgs.stdenv.hostPlatform.system;
  toolchain =
    (builtins.getFlake "github:moonbit-community/moonbit-overlay").packages.${system}.moonbit_latest;
  bp = import ./lib/moonPlatform/buildMoonbitPackage.nix { inherit (pkgs) lib stdenv; };
  lp = import ./lib/moonPlatform/linkMoonbitProgram.nix { inherit (pkgs) lib stdenv; };
  br = import ./lib/moonPlatform/buildMoonbitRuntime.nix { inherit (pkgs) stdenv; };
  me = import ./lib/moonPlatform/makeMoonbitExecutable.nix { inherit (pkgs) lib stdenv; };

  src = pkgs.writeTextDir "main.mbt" ''
    fn main {
      println("hi from native makeMoonbitExecutable")
    }
  '';

  core = bp {
    pname = "hello_main";
    pkg = "hello/main";
    inherit src toolchain;
    files = [ "main.mbt" ];
    isMain = true;
    target = "native";
  };
  cdrv = lp {
    pname = "hello_main";
    main = "hello/main";
    cores = [ { core = core; name = "hello_main"; } ];
    pkgSources = [ { pkg = "hello/main"; src = src; } ];
    target = "native";
    inherit toolchain;
  };
  runtime = br { inherit toolchain; };
in
me {
  pname = "hello_main";
  programC = cdrv;
  inherit runtime toolchain;
}
