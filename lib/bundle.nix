{
  symlinkJoin,
  makeWrapper,
  bubblewrap,
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
    MOON_HOME=$out PATH=$out/bin $out/bin/moon bundle --all --source-dir $out/lib/core

    mkdir -p $out/registry
    mv $out/bin/moon $out/bin/.moon-wrapped
    makeWrapper ${bubblewrap}/bin/bwrap $out/bin/moon \
      --run "export MOON_HOME=\''${NIX_MOON_HOME:-\$HOME/.moon}; mkdir -p \$MOON_HOME/registry" \
      --add-flags "--argv0 moon \
      --bind / / --dev-bind /dev /dev \
      --bind \$HOME/.moon/registry \$MOON_HOME/registry \
      --bind $out/bin \$MOON_HOME/bin \
      --bind $out/include \$MOON_HOME/include \
      --bind $out/lib \$MOON_HOME/lib \
      -- $out/bin/.moon-wrapped"
  '';
}
