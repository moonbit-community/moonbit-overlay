# Overlay interface for non-flake Nix.
final: prev:
let
  inherit (final) lib;
in
{
  moonbit-bin = (prev.moonbit-bin or { }) //
    import ./lib/moonbit-bin.nix {
      inherit lib;
      pkgs = final;
      versions = import ./versions;
    };
}
