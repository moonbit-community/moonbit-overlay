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

    # `moon lsp` and `moon ide` delegate to standalone helper binaries.  The
    # current native helpers still resolve the bundled core through MOON_HOME,
    # while `moon` itself uses MOON_TOOLCHAIN_ROOT.  Scope the legacy variable
    # to the helpers so normal `moon` commands keep their writable user home.
    if [ -e $out/bin/moon-ide ]; then
      wrapProgram $out/bin/moon-ide \
        --set MOON_TOOLCHAIN_ROOT $out \
        --set MOON_HOME $out
    fi

    # Recent toolchains ship a native `moon-lsp`; older releases shipped a
    # node script named `moonbit-lsp`.  Wrap whichever the toolchain provides.
    if [ -e $out/bin/moon-lsp ]; then
      wrapProgram $out/bin/moon-lsp \
        --set MOON_TOOLCHAIN_ROOT $out \
        --set MOON_HOME $out
    elif [ -e $out/bin/moonbit-lsp ]; then
      mv $out/bin/moonbit-lsp $out/bin/.moonbit-lsp-orig
      substitute $out/bin/.moonbit-lsp-orig $out/bin/moonbit-lsp \
        --replace-fail "#!/usr/bin/env node" "${''
          #!${nodejs}/bin/node
          process.env.MOON_TOOLCHAIN_ROOT = \"$out\";
          process.env.MOON_HOME = \"$out\";
        ''}"
      chmod +x $out/bin/moonbit-lsp
    fi
  '';
}
