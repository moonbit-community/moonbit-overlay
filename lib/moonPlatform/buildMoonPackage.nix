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

        # MOON_HOME from the nix store is read-only; moon needs to write
        # build caches and package metadata there, so create a writable copy.
        writable_home=$TMPDIR/moon_home
        cp -rL $MOON_HOME $writable_home
        chmod -R u+w $writable_home
        export MOON_HOME=$writable_home
        export HOME=$TMPDIR

        moon build ${lib.concatStringsSep " " moonFlags}
      '';
      installPhase = ''
        mkdir -p $out
        cp -r $TMP/_build/ $out/
      '';
      env = (args.env or { }) // {
        MOON_HOME = "${moonHome}";
      };
    in
    stdenv.mkDerivation (
      args
      // {
        inherit nativeBuildInputs env;
        unpackPhase = args.unpackPhase or unpackPhase;
        buildPhase = args.buildPhase or buildPhase;
        installPhase = args.installPhase or installPhase;
      }
    );
in
buildMoonPackage
