{
  nodejs,
  symlinkJoin,
  makeWrapper,
  # manually
  cli,
  core,
  ...
}:

symlinkJoin {
  name = "moonbit";
  paths = [
    cli
    core
  ];

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    export MOON_HOME=$out

    PATH=$out/bin $out/bin/${cli.meta.mainProgram} bundle --all --source-dir $out/lib/core

    wrapProgram $out/bin/${cli.meta.mainProgram} \
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
