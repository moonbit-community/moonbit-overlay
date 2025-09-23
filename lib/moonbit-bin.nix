{
  lib,
  pkgs,
  versions,
  coreSrc,
}:

let
  inherit (pkgs) stdenv callPackage;

  moonbitUri = "https://cli.moonbitlang.com";
  target =
    {
      "x86_64-linux" = "linux-x86_64";
      "x86_64-darwin" = "darwin-x86_64";
      "aarch64-darwin" = "darwin-aarch64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  mkVersion = v: lib.escapeURL (lib.removePrefix "v" v);
  mkCliUri = version: "${moonbitUri}/binaries/${mkVersion version}/moonbit-${target}.tar.gz";
  mkCoreUri = version: "${moonbitUri}/cores/core-${mkVersion version}.tar.gz";

  mk =
    ref: record:
    let
      escapeFrom = [
        "."
        "+"
      ];
      escapeTo = [
        "_"
        "-"
      ];
      escape = builtins.replaceStrings escapeFrom escapeTo;

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
        inherit version;
        url = mkCoreUri version;
        hash = record.coreHash;
      };

      moonbit.${escapedRef} = callPackage ./bundle.nix {
        cli = cli."${escapedRef}";
        core = core."${escapedRef}";
      };

      moonbit-lsp.${escapedRef} = callPackage ./lsp.nix {
        inherit version;
        bundle = moonbit."${escapedRef}";
      };
    };
in
builtins.foldl' lib.recursiveUpdate { } (builtins.attrValues (lib.mapAttrs mk versions))
