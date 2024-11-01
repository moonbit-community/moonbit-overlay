# moonbit-overlay

Binary distributed [moonbit](https://www.moonbitlang.com/) toolchains.

## Features
- the hard bound between [moon](https://github.com/moonbitlang/moon/) and [core](https://github.com/moonbitlang/core).
- not build from source.
- versioning!
- patchelf works :)

## TODO
- [ ] overridable
- [ ] build from source (core)

## Example

```nix
{
  description = "A startup basic moonbit project";

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
            ];
          };
      };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
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

> The original version of moonbit is written as `v0.1.20241031+7204facb6`,
> for convenience, we [escape](https://github.com/jetjinser/moonbit-overlay/blob/3464a68cf9a16d4d63f76de823ca9687bca2de2d/lib/moonbit-bin.nix#L22-L24)
> it to format like `v0_1_20241031-7204facb6`.

## Inspiration
the moonbit-overlay is inspired by [rust-overlay](https://github.com/oxalica/rust-overlay).
