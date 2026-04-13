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

    # patch the lsp to use the correct node and MOON_TOOLCHAIN_ROOT
    mv $out/bin/moonbit-lsp $out/bin/.moonbit-lsp-orig
    substitute $out/bin/.moonbit-lsp-orig $out/bin/moonbit-lsp \
      --replace-fail "#!/usr/bin/env node" "${''
        #!${nodejs}/bin/node
        process.env.MOON_TOOLCHAIN_ROOT = \"$out\";
      ''}"
    chmod +x $out/bin/moonbit-lsp
  '';
}
