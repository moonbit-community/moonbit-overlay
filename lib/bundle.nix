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
    export MOON_HOME=$out
    export PATH=$out/bin:$PATH

    $out/bin/moon bundle \
      -v --warn-list -a --all -C $out/lib/core ||
      error "Failed to bundle core"

    $out/bin/moon bundle \
      -v --warn-list -a --target llvm -C $out/lib/core ||
      error "Failed to bundle core to llvm"

    $out/bin/moon bundle \
      -v --warn-list -a --target wasm-gc -C $out/lib/core ||
      error "Failed to bundle core to wasm-gc"

    wrapProgram $out/bin/${toolchains.meta.mainProgram} \
      --set MOON_HOME $out

    # patch the lsp to use the correct node and MOON_HOME
    mv $out/bin/moonbit-lsp $out/bin/.moonbit-lsp-orig
    substitute $out/bin/.moonbit-lsp-orig $out/bin/moonbit-lsp \
      --replace-fail "#!/usr/bin/env node" "${''
        #!${nodejs}/bin/node
        process.env.MOON_HOME = \"$out\";
      ''}"
    chmod +x $out/bin/moonbit-lsp
  '';
}
