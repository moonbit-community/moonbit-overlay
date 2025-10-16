{
  lib,
  pkgs,
  versions,
  minVersion,
}:

let
  inherit (pkgs) callPackage;

  inherit (callPackage ./utils.nix { })
    mkToolChainsUri
    target
    escape
    mkCoreUri
    ;

  mk =
    ref: record:
    let
      version = record.version;
      escapedRef = escape ref;
    in
    if lib.versionOlder (lib.removePrefix "v" version) minVersion then
      {
        moon-patched.${escapedRef} = pkgs.emptyFile;
        cli.${escapedRef} = pkgs.emptyFile;
        core.${escapedRef} = pkgs.emptyFile;
        moonbit.${escapedRef} = pkgs.emptyFile;
      }
    else
      rec {
        moon-patched.${escapedRef} = callPackage ./moon-patched {
          rev = record.moonRev;
          hash = record.moonHash;
        };
        cli.${escapedRef} = callPackage ./cli.nix {
          inherit version;
          moon-patched = moon-patched.${escapedRef};
          url = mkToolChainsUri version;
          hash = record."${target}-cliHash";
        };
        core.${escapedRef} = callPackage ./core.nix {
          inherit version;
          url = mkCoreUri version;
          hash = record.coreHash;
        };

        moonbit.${escapedRef} = callPackage ./bundle.nix {
          cli = cli."${escapedRef}";
          core = core."${escapedRef}";
        };
      };

  flattenAttrs = lib.foldl' (
    acc: item:
    acc
    // (builtins.listToAttrs (
      builtins.concatMap (
        pkgType:
        let
          pkgVersions = item.${pkgType};
        in
        lib.mapAttrsToList (ver: val: {
          name = "${pkgType}_${ver}";
          value = val;
        }) pkgVersions
      ) (builtins.attrNames item)
    ))
  ) { };

  versionPkgs = builtins.attrValues (lib.mapAttrs mk versions);
in
{
  packages = flattenAttrs versionPkgs;
  legacyPackages = builtins.foldl' lib.recursiveUpdate { } versionPkgs;
}
