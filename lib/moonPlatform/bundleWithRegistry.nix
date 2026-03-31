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

    pushd $out/lib/core
    PATH=$out/bin $out/bin/${toolchains.meta.mainProgram} bundle --all
    popd

    wrapProgram $out/bin/${toolchains.meta.mainProgram} \
      --set MOON_HOME $out
  '';
}
