# Smoke test for the fine-grained builders: compile + link a trivial main package
# straight through buildMoonbitPackage / linkMoonbitProgram, no `moon`/mymoon involved.
#   nix build .#checks.x86_64-linux.testFineGrained
{ pkgs, toolchain }:
let
  platform = pkgs.moonPlatform;

  src = pkgs.writeTextDir "main.mbt" ''
    fn main {
      println("hi from buildMoonbitPackage framework")
    }
  '';

  core = platform.buildMoonbitPackage {
    pname = "hello_main";
    pkg = "hello/main";
    inherit src toolchain;
    files = [ "main.mbt" ];
    isMain = true;
  };
in
platform.linkMoonbitProgram {
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
  inherit toolchain;
}
