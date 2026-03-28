# Main builder of moonPlatform.
#
# Reads moon.mod.json to determine version, source directory, and preferred
# build target so callers need minimal configuration:
#
#   pkgs.moonPlatform.buildMoonPackage {
#     src = ./.;
#     moonModJson = ./moon.mod.json;
#     moonRegistryIndex = inputs.moon-registry;
#   }
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
      moonMainPkg ? null,
      moonTarget ? null,
      ...
    }@args:
    let
      moonMod = builtins.fromJSON (builtins.readFile moonModJson);

      # Auto-detect from moon.mod.json
      # name is "owner/repo" in moon.mod.json; use the last component
      derivedName = lib.last (lib.splitString "/" (moonMod.name or "moon-package"));
      derivedVersion = moonMod.version or "0.0.0";
      sourceDir = moonMod.source or "src";
      preferredTarget = moonMod.preferred-target or "native";

      effectiveTarget = if moonTarget != null then moonTarget else preferredTarget;

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

        moon build \
          --target ${effectiveTarget} \
          --release \
          ${lib.concatStringsSep " " moonFlags}
      '';

      # Find and install all executable binaries produced by the build.
      installPhase = ''
        mkdir -p $out/bin
        find $TMP/_build/${effectiveTarget}/release/build/ \
          -name '*.exe' -type f -perm -0111 \
          -exec sh -c '
            for f; do
              base="$(basename "$f" .exe)"
              install -Dm755 "$f" "$out/bin/$base"
            done
          ' _ {} +
      '';

      env = (args.env or { }) // {
        MOON_HOME = "${moonHome}";
      };
    in
    stdenv.mkDerivation (
      (builtins.removeAttrs args [
        "moonModJson"
        "moonRegistryIndex"
        "moonFlags"
        "moonMainPkg"
        "moonTarget"
      ])
      // {
        name = args.name or derivedName;
        version = args.version or derivedVersion;
        inherit nativeBuildInputs env;
        unpackPhase = args.unpackPhase or unpackPhase;
        buildPhase = args.buildPhase or buildPhase;
        installPhase = args.installPhase or installPhase;
      }
    );
in
buildMoonPackage
