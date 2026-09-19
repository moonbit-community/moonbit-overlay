# Smoke test for the native fine-grained builders: compile → link (.c) → runtime →
# cc-link into an executable, no `moon`/mymoon involved.
#   nix build .#checks.x86_64-linux.testNative
{ pkgs, toolchain }:
let
  platform = pkgs.moonPlatform;

  src = pkgs.writeTextDir "main.mbt" ''
    fn main {
      println("hi from native makeMoonbitExecutable")
    }
  '';

  core = platform.buildMoonbitPackage {
    pname = "hello_main";
    pkg = "hello/main";
    inherit src toolchain;
    files = [ "main.mbt" ];
    isMain = true;
    target = "native";
  };
  cdrv = platform.linkMoonbitProgram {
    pname = "hello_main";
    main = "hello/main";
    cores = [
      {
        core = core;
        name = "hello_main";
      }
    ];
    pkgSources = [
      {
        pkg = "hello/main";
        src = src;
      }
    ];
    target = "native";
    inherit toolchain;
  };
  runtime = platform.buildMoonbitRuntime { inherit toolchain; };
in
platform.makeMoonbitExecutable {
  pname = "hello_main";
  programC = cdrv;
  inherit runtime toolchain;
}
