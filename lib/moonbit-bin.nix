{ lib
, pkgs
, versions
}:

# TODO: overridable
#       build from source

let
  inherit (pkgs) stdenv callPackage;

  moonbitUri = lib.fileContents ../uri.txt;

  mkCliUri = version: "${cliMoonbit}/binaries/${version}/moonbit-${target}.tar.gz";
  mkCoreUri = version: "${cliMoonbit}/cores/core-${version}.tar.gz";

  mkVersion = v: lib.escapeURL (lib.removePrefix "v" v);
  mkCliUri = version: "${moonbitUri}/binaries/${mkVersion version}/moonbit-${target}.tar.gz";
  mkCoreUri = version: "${moonbitUri}/cores/core-${mkVersion version}.tar.gz";

  mk = _: record:
    let
      escapeFrom = [ "." "+" ];
      escapeTo = [ "_" "-" ];
      escape = builtins.replaceStrings escapeFrom escapeTo;

      version = record.version;
      escapedVersion = escape version;
    in
    rec {
      cli.${escapedVersion} = callPackage ./cli.nix {
        inherit version;
        url = mkCliUri version;
        hash = record.cliHash;
      };
      core.${escapedVersion} = callPackage ./core.nix {
        inherit version;
        url = mkCoreUri version;
        hash = record.coreHash;
      };

      moonbit.${escapedVersion} = callPackage ./bundle.nix {
        cli = cli."${escapedVersion}";
        core = core."${escapedVersion}";
      };
    };
in
builtins.foldl' lib.recursiveUpdate { }
  (builtins.attrValues (lib.mapAttrs mk versions))
