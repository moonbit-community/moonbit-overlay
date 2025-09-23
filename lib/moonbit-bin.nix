{
  lib,
  pkgs,
  versions,
  coreSrc,
}:

let
  inherit (pkgs) callPackage;

  inherit (callPackage ./utils.nix { }) mkCliUri target escape;

  mk =
    ref: record:
    let
      version = record.version;
      escapedRef = escape ref;
    in
    rec {
      cli.${escapedRef} = callPackage ./cli.nix {
        inherit version;
        url = mkCliUri version;
        hash = record."${target}-cliHash";
      };
      core.${escapedRef} = callPackage ./core.nix {
        inherit version coreSrc;
      };

      moonbit.${escapedRef} = callPackage ./bundle.nix {
        cli = cli."${escapedRef}";
        core = core."${escapedRef}";
      };
    };
in
builtins.foldl' lib.recursiveUpdate { } (builtins.attrValues (lib.mapAttrs mk versions))
