{
  lib,
  pkgs,
  versions,
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
    rec {
      moon-patched.${escapedRef} = callPackage ./moon-patched {
        rev = record.moonRev;
        hash = record.moonHash;
      };
      toolchains.${escapedRef} = callPackage ./toolchains.nix {
        inherit version;
        moon-patched = moon-patched.${escapedRef};
        url = mkToolChainsUri version;
        hash = record."${target}-toolchainsHash";
      };
      core.${escapedRef} = callPackage ./core.nix {
        inherit version;
        url = mkCoreUri version;
        hash = record.coreHash;
      };

      moonbit.${escapedRef} = callPackage ./bundle.nix {
        toolchains = toolchains."${escapedRef}";
        core = core."${escapedRef}";
      };
    };
in
builtins.foldl' lib.recursiveUpdate { } (builtins.attrValues (lib.mapAttrs mk versions))
