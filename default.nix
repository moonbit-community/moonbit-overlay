# Use the caller's package set for binary patching and runtime dependencies.
final: prev: {
  moonbit-bin = (prev.moonbit-bin or { }) // import ./lib/moonbit-bin.nix { pkgs = final; };
}
