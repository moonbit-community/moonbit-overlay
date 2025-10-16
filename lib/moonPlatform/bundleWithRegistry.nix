# Registry-pluggable bundle of moonbit-bin.
{
  symlinkJoin,
  makeWrapper,
  toolchains,
  core,
}:
{
  cachedRegistry,
}:

symlinkJoin {
  name = "moonPlatform-moonHome";
  paths = [
    toolchains
    core
    cachedRegistry
  ];

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    export MOON_HOME=$out

    PATH=$out/bin $out/bin/${toolchains.meta.mainProgram} bundle --all --source-dir $out/lib/core

    wrapProgram $out/bin/${toolchains.meta.mainProgram} \
      --set MOON_HOME $out
  '';
}
