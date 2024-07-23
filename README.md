# moonbit-overlay

Binary distributed [moonbit](https://www.moonbitlang.com/) toolchains.

Features:
  - the hard bound between [moon](https://github.com/moonbitlang/moon/) and [core](https://github.com/moonbitlang/core).
  - not build from source.
  - non-producible due to [non-versioning](https://github.com/moonbitlang/moonbit-docs/issues/131).
  - patchelf works :)

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

## Inspiration
the moonbit-overlay is inspired by [rust-overlay](https://github.com/oxalica/rust-overlay).
