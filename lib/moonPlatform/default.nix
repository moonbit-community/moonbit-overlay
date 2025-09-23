# moonPlatform
# Basic strategy:
# 1. List up all dependencies of root moon.mod.json
#    ./parseMoonIndex.nix
#    ./listAllDependencies.nix
# 2. Fetch all dependencies into $MOON_HOME/registry/cache
# 3. Bundle core, cli and cached registry
# 4. Build moon package with bundled $MOON_HOME
{
  lib,
  fetchurl,
  stdenv,
  symlinkJoin,
  makeWrapper,
  system,
  callPackage,
  # manually
  versions,
  coreSrc,
}:
{
  # public API
  version,
}:
let
  inherit (import ../utils.nix { inherit stdenv lib; }) mkCliUri target;
  
  cli = callPackage ../cli.nix {
    inherit version;
    url = mkCliUri version;
    hash = versions."${version}"."${target}-cliHash";
  };

  core = callPackage ../core.nix {
    inherit version coreSrc;
  };

  fetchMoonPackage = import ./fetchMoonPackage.nix {
    inherit fetchurl;
  };

  parseMoonIndex = import ./parseMoonIndex.nix {
    inherit lib;
  };

  listAllDependencies = import ./listAllDependencies.nix {
    inherit parseMoonIndex lib;
  };

  buildCachedRegistry = import ./buildCachedRegistry.nix {
    inherit
      fetchMoonPackage
      listAllDependencies
      lib
      stdenv
      ;
  };

  bundleWithRegistry = import ./bundleWithRegistry.nix {
    inherit
      symlinkJoin
      makeWrapper
      cli
      core
      ;
  };

  buildMoonPackage = import ./buildMoonPackage.nix {
    inherit
      lib
      stdenv
      buildCachedRegistry
      bundleWithRegistry
      ;
  };
in
{
  inherit
    buildCachedRegistry
    buildMoonPackage
    ;
}
