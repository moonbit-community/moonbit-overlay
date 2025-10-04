# Registry-pluggable bundle of moonbit-bin.
{
  symlinkJoin,
  makeWrapper,
  cli,
  core,
}:
{
  cachedRegistry,
}:

symlinkJoin {
  name = "moonPlatform-moonHome";
  paths = [
    cli
    core
    cachedRegistry
  ];

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    export MOON_HOME=$out

    PATH=$out/bin $out/bin/${cli.meta.mainProgram} bundle --all --source-dir $out/lib/core

    wrapProgram $out/bin/${cli.meta.mainProgram} \
      --set MOON_HOME $out
  '';
}
