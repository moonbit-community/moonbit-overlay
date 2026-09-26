{ pkgs }:
let
  inherit (pkgs) lib callPackage;
  inherit (callPackage ./utils.nix { }) target mkToolChainsUri mkCoreUri;
  versions = import ../versions.nix lib;
  # v0.10 is the first SDK generation with the current native helper layout.
  # Keep older release metadata for archival purposes without exporting those
  # snapshots as supported packages.
  minVersion = "0.10.0";
  supported = lib.filterAttrs (
    ref: record:
    record ? "${target}-toolchainsHash"
    && (
      builtins.elem ref [
        "latest"
        "nightly"
        "updating"
      ]
      || lib.hasPrefix "nightly-" ref
      || lib.versionAtLeast (lib.removePrefix "v" record.version) minVersion
    )
  ) versions;
  mkToolchain =
    _: record:
    let
      inherit (record) version;
      toolchains = callPackage ./toolchains.nix {
        inherit version;
        url = mkToolChainsUri version;
        hash = record."${target}-toolchainsHash";
      };
      core = callPackage ./core.nix {
        inherit version;
        url = mkCoreUri version;
        hash = record.coreHash;
      };
    in
    callPackage ./bundle.nix { inherit toolchains core; };
in
lib.mapAttrs mkToolchain supported
