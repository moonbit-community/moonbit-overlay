# moonbit-overlay

Binary distributed [MoonBit](https://www.moonbitlang.com/) toolchains.

## Quick Start

### Run [moon](https://github.com/moonbitlang/moon) in one line:
```nix
nix run github:jetjinser/moonbit-overlay#moon
```

### List all available binaries:
```nix
nix run github:jetjinser/moonbit-overlay#<tab>
```

### Create devshell from template:
```bash
nix flake init -t github:jetjinser/moonbit-overlay
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
    moonbit-overlay.url = "github:jetjinser/moonbit-overlay";
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
              moonbit-bin.lsp.latest
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

## Bundled MoonBit Toolchains

```nix
moonbit-bin.moonbit.latest
```

## MoonBit LSP (extracted from [moonbit-lang vscode extention](https://marketplace.visualstudio.com/items?itemName=moonbit.moonbit-lang))

```nix
moonbit-bin.lsp.latest
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
> for convenience, we [escape](https://github.com/jetjinser/moonbit-overlay/blob/3464a68cf9a16d4d63f76de823ca9687bca2de2d/lib/moonbit-bin.nix#L22-L24)
> it to format like `v0_1_20241031-7204facb6`.

## TODO
- [ ] overridable
- [x] build from source (core)
- [ ] re-support legacy default.nix


## Inspiration
the moonbit-overlay is inspired by [rust-overlay](https://github.com/oxalica/rust-overlay).
