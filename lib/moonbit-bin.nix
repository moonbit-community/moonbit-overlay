{ lib
, pkgs
, versions
}:

# TODO: overridable
#       unbound version

let
  inherit (pkgs) stdenv callPackage;

  cliMoonbit = import ./uri.nix;
  # x86_64-linux => linux-x86_64
  target = with lib; concatStringsSep "-" (reverseList (splitString "-" stdenv.system));

  mkCliUri = version: "${cliMoonbit}/binaries/${version}/moonbit-${target}.tar.gz";
  mkCoreUri = version: "${cliMoonbit}/cores/core-${version}.tar.gz";

  mk = version: hashes: rec {
    cli.${version} = callPackage ./cli.nix {
      inherit version;
      url = mkCliUri version;
      hash = hashes.cliHash;
    };
    core.${version} = callPackage ./core.nix {
      inherit version;
      url = mkCoreUri version;
      hash = hashes.coreHash;
    };

    moonbit.${version} = callPackage ./bundle.nix {
      cli = cli."${version}";
      core = core."${version}";
    };
  };
in
builtins.foldl' lib.recursiveUpdate { }
  (builtins.attrValues (lib.mapAttrs mk versions))
