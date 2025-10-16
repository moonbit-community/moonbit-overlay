# moonPlatform
# Basic strategy:
# 1. List up all dependencies of root moon.mod.json
#    ./parseMoonIndex.nix
#    ./listAllDependencies.nix
# 2. Fetch all dependencies into $MOON_HOME/registry/cache
# 3. Bundle core, toolchains and cached registry
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
}:
{
  # public API
  version,
}:
let
  inherit (import ../utils.nix { inherit stdenv lib; }) mkToolChainsUri mkCoreUri target;

  moon-patched = callPackage ../moon-patched {
    rev = versions.${version}.moonRev;
    hash = versions.${version}.moonHash;
  };

  toolchains = callPackage ../toolchains.nix {
    inherit version moon-patched;
    url = mkToolChainsUri version;
    hash = versions."${version}"."${target}-toolchainsHash";
  };

  core = callPackage ../core.nix {
    inherit version;
    url = mkCoreUri version;
    hash = versions."${version}".coreHash;
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
      toolchains
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
