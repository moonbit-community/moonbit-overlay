# Builder for registry with all dependencies cached.
# Takes $MOON_HOME/registry/index/ and returns subset of $MOON_HOME
# including only $MOON_HOME/registry/*.
{
  lib,
  fetchMoonPackage,
  listAllDependencies,
  stdenv,
}:
{
  registryIndexSrc, # path to $MOON_HOME/registry/index/
  moonModJson, # path to <workspace>/moon.mod.json
}:
let
  moonMod = builtins.fromJSON (builtins.readFile moonModJson);
  moonModDepsSet = moonMod.deps or { };
  moonModDepsList = lib.mapAttrsToList (name: version: { inherit name version; }) moonModDepsSet;
  dependencyList = listAllDependencies {
    inherit registryIndexSrc;
    unresolvedDependencies = moonModDepsList;
  };
  buildCachedRegistry = stdenv.mkDerivation {
    name = "cached-moon-registry";
    src = registryIndexSrc;
    phases = [ "installPhase" ];
    installPhase =
      ''
        mkdir -p $out/registry/index
        cp -r $src/* $out/registry/index/
      ''
      + (lib.strings.concatMapStringsSep "\n" (
        dep:
        let
          cache = fetchMoonPackage {
            name = dep.name;
            version = dep.version;
            sha256 = dep.checksum;
          };
        in
        ''
          mkdir -p $out/registry/cache/${dep.name}
          cp ${cache} $out/registry/cache/${dep.name}/${dep.version}.zip
        ''
      ) dependencyList);
  };
in
buildCachedRegistry
