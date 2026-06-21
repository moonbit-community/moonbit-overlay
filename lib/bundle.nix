{
  nodejs,
  symlinkJoin,
  makeWrapper,
  # manually
  toolchains,
  core,
  ...
}:

symlinkJoin {
  name = "moonbit";
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
      -v --warn-list -a --all ||
      error "Failed to bundle core"

    $out/bin/moon -C $out/lib/core bundle \
      -v --warn-list -a --target llvm ||
      error "Failed to bundle core to llvm"

    $out/bin/moon -C $out/lib/core bundle \
      -v --warn-list -a --target wasm-gc ||
      error "Failed to bundle core to wasm-gc"

    wrapProgram $out/bin/${toolchains.meta.mainProgram} \
      --set MOON_TOOLCHAIN_ROOT $out

    # The lsp server needs MOON_TOOLCHAIN_ROOT pointing at $out. As of recent
    # nightlies it is a native binary named `moon-lsp` (it used to be a node
    # script named `moonbit-lsp`, patched by rewriting its shebang). Wrap
    # whichever the toolchain ships, and keep a `moonbit-lsp` alias for
    # consumers still invoking the old name.
    if [ -e $out/bin/moon-lsp ]; then
      wrapProgram $out/bin/moon-lsp --set MOON_TOOLCHAIN_ROOT $out
      ln -sf moon-lsp $out/bin/moonbit-lsp
    elif [ -e $out/bin/moonbit-lsp ]; then
      mv $out/bin/moonbit-lsp $out/bin/.moonbit-lsp-orig
      substitute $out/bin/.moonbit-lsp-orig $out/bin/moonbit-lsp \
        --replace-fail "#!/usr/bin/env node" "${''
          #!${nodejs}/bin/node
          process.env.MOON_TOOLCHAIN_ROOT = \"$out\";
        ''}"
      chmod +x $out/bin/moonbit-lsp
    fi
  '';
}
