# moonbit-overlay

Versioned, binary-distributed [MoonBit](https://www.moonbitlang.com/) toolchains
for Nix. Each package contains the matching compiler, CLI, language server,
runtime tools, and bundled core library.

This repository handles toolchain distribution. MoonBit project builds and
Mooncakes dependency packaging belong to
[**moon2nix**](https://github.com/moonbit-community/moon2nix).

## Quick start

```bash
nix run github:moonbit-community/moonbit-overlay#moon -- version
nix run github:moonbit-community/moonbit-overlay#moon -- lsp --version
nix shell github:moonbit-community/moonbit-overlay#latest
nix shell github:moonbit-community/moonbit-overlay#nightly
```

`nix run github:moonbit-community/moonbit-overlay` runs `moon` from `latest`.
The `moonx` app runs executable packages from Mooncakes:

```bash
nix run github:moonbit-community/moonbit-overlay#moonx -- user/module/package
```

## Development shell

```bash
nix flake init -t github:moonbit-community/moonbit-overlay
```

The template puts its flake in `nix/`; run `nix develop ./nix`.

Alternatively, apply the overlay to your own nixpkgs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
  };

  outputs = { nixpkgs, moonbit-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ moonbit-overlay.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.moonbit-bin.latest ];
      };
    };
}
```

Without an overlay, use
`moonbit-overlay.packages.${system}.latest` directly. The overlay uses the
caller's nixpkgs for binary patching and runtime dependencies.

Non-flake users can apply `import ./default.nix` as an overlay to a pinned
checkout of this repository.

## Versions and platforms

Each public package is a complete toolchain:

```nix
pkgs.moonbit-bin.latest
pkgs.moonbit-bin.nightly
pkgs.moonbit-bin."v0.10.12+1634b282e+55ca257"
```

Flake packages use the same names; `default` is an alias for `latest`.
Version names are the original release identifiers, without escaping dots or
plus signs. Available snapshots are recorded in [versions/toolchains](versions/toolchains).
Versions older than `0.10.0` are retained as historical metadata but are not
exposed. Version 0.10 is the first supported SDK generation with the current
native helper layout, including `moon-lsp`.

Packages are exposed only when the snapshot has a hash for the requested host
platform. The flake supports `x86_64-linux` and `aarch64-darwin`. Intel macOS is not
exposed: the recorded snapshots have no binary hashes for that platform, and
the locked nixpkgs no longer supports it.

`latest` resolves to a concrete release mirrored in this repository's GitHub
releases. Pin the overlay revision (for example with `flake.lock`) to keep it
fixed. `nightly` points to the newest nightly mirrored by this repository.
Changed nightly builds are also exposed by date, for example
`pkgs.moonbit-bin."nightly-2026-09-22"`, and stored as immutable prereleases so
older lock files remain fetchable.

## Editor support

Configure the language server as command `moon`, argument `lsp`. It is included
in the full toolchain; no separate LSP package is needed.

## Migrating from the previous interface

| Previous interface | Replacement |
| --- | --- |
| `pkgs.moonbit-bin.moonbit.latest` | `pkgs.moonbit-bin.latest` |
| `packages.${system}.moonbit_latest` | `packages.${system}.latest` |
| Escaped version attributes such as `v0_10_12-1634b282e-55ca257` | Quoted original version, `"v0.10.12+1634b282e+55ca257"` |
| `legacyPackages.${system}.moonbit` | `packages.${system}` |
| `overlays.moonbit-overlay` | `overlays.default` |
| `templates.moonbit-dev` | `templates.default` |
| Separate `toolchains`, `core`, `compiler`, or `lsp` packages | Complete toolchain package |
| `moonPlatform`, `mkMoonPlatform`, and project/registry builders | Use moon2nix for project builds |

The project builders and dependency fixtures have moved to moon2nix. The
obsolete patched moon implementation has been removed. The toolchain does not resolve project dependencies.

## Design

Static release metadata is mapped to complete toolchain derivations. Internal
steps fetch and patch the official binaries, install the matching core, bundle
it, and wrap the tools for Nix.

## License

[MIT](LICENSE).
