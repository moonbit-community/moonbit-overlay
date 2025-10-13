{
  lib,
  pkgs,
  versions,
}:

let
  inherit (pkgs) callPackage;

  inherit (callPackage ./utils.nix { }) mkCliUri target escape mkCoreUri;

  mk =
    ref: record:
    let
      version = record.version;
      escapedRef = escape ref;
    in
    rec {
      moon-patched.${escapedRef} = callPackage ./moon-patched.nix {
        rev = record.moonRev;
        hash = record.moonHash;
      };
      cli.${escapedRef} = callPackage ./cli.nix {
        inherit version;
        moon-patched = moon-patched.${escapedRef};
        url = mkCliUri version;
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
in
builtins.foldl' lib.recursiveUpdate { } (builtins.attrValues (lib.mapAttrs mk versions))
