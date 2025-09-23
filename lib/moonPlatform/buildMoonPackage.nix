# Main builder of moonPlatform.
# TODO: Build target specific control of $out destination.
{
  lib,
  stdenv,
  buildCachedRegistry,
  bundleWithRegistry,
  ...
}:
let
  buildMoonPackage =
    {
      moonModJson,
      moonRegistryIndex,
      moonFlags ? [ ],
      ...
    }@args:
    let
      cachedRegistry = buildCachedRegistry {
        inherit moonModJson;
        registryIndexSrc = moonRegistryIndex;
      };
      moonHome = bundleWithRegistry {
        inherit cachedRegistry;
      };
      nativeBuildInputs = lib.lists.unique ((args.nativeBuildInputs or [ ]) ++ [ moonHome ]);
      unpackPhase = ''
        mkdir -p $TMP
        cp -r $src/* $TMP
      '';
      buildPhase = ''
        cd $TMP
        moon build ${lib.concatStringsSep " " moonFlags}
      '';
      installPhase = ''
        mkdir -p $out
        cp -r $TMP/target/ $out/
      '';
      env = (args.env or { }) // {
        MOON_HOME = "${moonHome}";
      };
    in
    stdenv.mkDerivation (
      args
      // {
        inherit
          nativeBuildInputs
          unpackPhase
          buildPhase
          installPhase
          env
          ;
      }
    );
in
buildMoonPackage
