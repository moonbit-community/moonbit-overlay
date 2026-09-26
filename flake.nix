{
  description = "Versioned binary MoonBit toolchains";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      packagesFor = pkgs: import ./lib/moonbit-bin.nix { inherit pkgs; };
      treefmtEval = forEachSystem (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      overlays.default = import ./default.nix;
      packages = forEachSystem (
        system:
        let
          packages = packagesFor nixpkgs.legacyPackages.${system};
        in
        packages // lib.optionalAttrs (packages ? latest) { default = packages.latest; }
      );
      apps = forEachSystem (
        system:
        let
          packages = self.packages.${system};
          mkApp = name: {
            type = "app";
            program = lib.getExe' packages.default name;
          };
        in
        lib.optionalAttrs (packages ? default) (
          lib.genAttrs [
            "moon"
            "moonx"
            "moonc"
            "mooncake"
            "moon_cove_report"
            "moondoc"
            "moonfmt"
            "mooninfo"
            "moonrun"
          ] mkApp
          // {
            default = mkApp "moon";
          }
        )
      );
      templates.default = {
        path = ./moonbit-dev;
        description = "A MoonBit development shell";
      };
      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);
      checks = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
          moonbit = packages.default;
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;
        }
        // lib.optionalAttrs (packages ? default) {
          testToolchainHelpers =
            pkgs.runCommand "test-moonbit-toolchain-helpers"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                set -euxo pipefail

                test -x ${moonbit}/bin/moon-lsp
                test -x ${moonbit}/bin/moon-ide

                # `moonx` is a symlink to `moon` (argv[0] dispatch, like the
                # official installer) and must expose the moonx CLI.
                test -L ${moonbit}/bin/moonx
                test -x ${moonbit}/bin/moonx
                ${moonbit}/bin/moonx --help > moonx-help.txt
                grep -Fq "Usage: moonx " moonx-help.txt

                grep -Fq "export MOON_TOOLCHAIN_ROOT='${moonbit}'" ${moonbit}/bin/moon-lsp
                grep -Fq 'export MOON_HOME=''${MOON_HOME-' ${moonbit}/bin/moon-lsp
                grep -Fq "export MOON_TOOLCHAIN_ROOT='${moonbit}'" ${moonbit}/bin/moon-ide
                grep -Fq 'export MOON_HOME=''${MOON_HOME-' ${moonbit}/bin/moon-ide

                # `moon lsp` dispatches to the bundled helper; do not add a
                # compatibility link for the old `moonbit-lsp` name.
                test ! -e ${moonbit}/bin/moonbit-lsp
                test ! -L ${moonbit}/bin/moonbit-lsp

                export HOME=$TMPDIR/home
                mkdir -p "$HOME"
                unset MOON_HOME MOON_TOOLCHAIN_ROOT
                # Do not add the toolchain to PATH: the moon wrapper must find
                # its own helpers, just as it must when launched through nix run.
                ${moonbit}/bin/moon lsp --version >/dev/null
                ${moonbit}/bin/moon ide --help >/dev/null
                python ${./tests/lsp-smoke.py} ${moonbit}/bin/moon

                touch $out
              '';
        }
      );
    };
}
