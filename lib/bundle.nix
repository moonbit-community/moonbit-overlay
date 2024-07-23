{ symlinkJoin
, makeWrapper
  # manually
, cli
, core
, ...
}:

symlinkJoin {
  name = "moonbit";
  paths = [ cli core ];

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    export MOON_HOME=$out
    PATH=$out/bin $out/bin/${cli.meta.mainProgram} bundle --all --source-dir $out/lib/core

    wrapProgram $out/bin/${cli.meta.mainProgram} \
      --set MOON_HOME $out
  '';
}
