# moonbit-overlay

Binary distributed [MoonBit](https://www.moonbitlang.com/) toolchains.

NOTE: [moonbit-compiler](https://github.com/moonbitlang/moonbit-compiler) was already open sourced, BUT *only* wasm-gc backend is available. Considering this is an incomplete compiler and the version is quite lagging, this project will still only be able to use patched pre-built binaries for a long time.

## Quick Start

### Run [moon](https://github.com/moonbitlang/moon) in one line

```bash
nix run github:moonbit-community/moonbit-overlay#moon
```

### List all available binaries

```bash
nix run github:moonbit-community/moonbit-overlay#<tab>
```

### Create devshell from template

```bash
nix flake init -t github:moonbit-community/moonbit-overlay
```

## Features

- build from source in future.
- versioning!
- patchelf works :)

## Example

### flake with overlay

```nix
{
  description = "A startup basic MoonBit project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devshell.url = "github:numtide/devshell";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];

      perSystem = { inputs', system, pkgs, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.moonbit-overlay.overlays.default ];
        };

        devshells.default = {
            packages = with pkgs; [
              moonbit-bin.moonbit.latest
            ];
          };
      };

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
```

## Moonbit Package Builder

```nix

{
  description = "A startup basic MoonBit project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    moon-registry = {
      url = "mooncakes.io/git/index";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      perSystem = { inputs', system, pkgs, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.moonbit-overlay.overlays.default ];
        };

        packages.default = pkgs.moonPlatform.buildMoonPackage {
          name = "my-brilliant-moonbit-project";
          src = ./.;
          version = "0.1.0";
          moonModJson = ./moon.mod.json;
          moonRegistryIndex = inputs.moon-registry;
          moonFlags = [ "--release" ];
        }
      };

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
```

## Bundled MoonBit Toolchains

```nix
moonbit-bin.moonbit.latest
```

## MoonBit LSP (distributed with compiler)

The moonbit-bin.moonbit.${version} package already includes moonbit-lsp.

```nix
moonbit-bin.moonbit.latest
```

## Version

### latest

```nix
moonbit-bin.moonbit.latest
```

### specific version

```nix
moonbit-bin.moonbit.v0_1_20241031-7204facb6
```

Check available versions in the [directory](versions/).

> The original version of MoonBit is written as `v0.1.20241031+7204facb6`,
> for convenience, we [escape](https://github.com/moonbit-community/moonbit-overlay/blob/3464a68cf9a16d4d63f76de823ca9687bca2de2d/lib/moonbit-bin.nix#L22-L24)
> it to format like `v0_1_20241031-7204facb6`.

## legacyPackages & packages

The overlay now provides both `legacyPackages` and `packages` attributes:

- **legacyPackages**: This is the original, structured attribute set. Packages are grouped by type (e.g., `moonbit`, `cli`, `core`) and version, making it easier to navigate the package hierarchy.
- **packages**: This is a flattened attribute set, where each package is exposed as a single attribute (e.g., `moonbit_latest`, `cli_v0_1_20241031-7204facb6`). This structure is required for `nix flake check` to work correctly, as it expects all packages to be directly accessible under the `packages` attribute.

Both are provided to maintain compatibility and usability: use `legacyPackages` for structured access, and `packages` for flake checks and direct access.

Some deprecated packages are still exposed for compatibility; attempting to use them will show a warning and prevent building.

## TODO

- [ ] overridable
- [ ] build from source (core)
  see [pull#10](https://github.com/moonbit-community/moonbit-overlay/pull/10)
- [ ] re-support legacy default.nix

## Inspiration

The moonbit-overlay is heavily inspired by [rust-overlay](https://github.com/oxalica/rust-overlay).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
