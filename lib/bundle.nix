{
  symlinkJoin,
  makeWrapper,
  # manually
  toolchains,
  core,
  ...
}:

symlinkJoin {
  name = "moonbit-${toolchains.version}";
  inherit (toolchains) version meta;
  paths = [
    toolchains
    core
  ];

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    export MOON_TOOLCHAIN_ROOT=$out
    export PATH=$out/bin:$PATH

    $out/bin/moon -C $out/lib/core bundle \
      -v --warn-list -a --all || {
      echo "Failed to bundle core" >&2
      exit 1
    }

    $out/bin/moon -C $out/lib/core bundle \
      -v --warn-list -a --target llvm || {
      echo "Failed to bundle core to llvm" >&2
      exit 1
    }

    $out/bin/moon -C $out/lib/core bundle \
      -v --warn-list -a --target wasm-gc || {
      echo "Failed to bundle core to wasm-gc" >&2
      exit 1
    }

    # Subcommand dispatch must find the bundled helpers even via `nix run`.
    wrapProgram $out/bin/${toolchains.meta.mainProgram} \
      --prefix PATH : $out/bin \
      --set MOON_TOOLCHAIN_ROOT $out

    # `moonx` is another entrance to the `moon` executable: the binary selects
    # the `moonx` CLI when its invoked name (argv[0]) is `moonx`, so the
    # official installer ships `moonx` as a symlink to `moon`.
    ln -sfn moon $out/bin/moonx

    # `moon lsp` and `moon ide` delegate to standalone helper binaries.  Keep a
    # caller-provided MOON_HOME, but default it to this immutable SDK for helpers
    # from releases that still use MOON_HOME to locate the bundled core.
    if [ -e $out/bin/moon-ide ]; then
      wrapProgram $out/bin/moon-ide \
        --set MOON_TOOLCHAIN_ROOT $out \
        --set-default MOON_HOME $out
    fi

    # `moon lsp` dispatches to this helper. MOON_HOME remains a user-overridable
    # compatibility input used by the native helper to locate the bundled core.
    if [ -e $out/bin/moon-lsp ]; then
      wrapProgram $out/bin/moon-lsp \
        --set MOON_TOOLCHAIN_ROOT $out \
        --set-default MOON_HOME $out
    fi
    rm -f $out/bin/moonbit-lsp
  '';
}
