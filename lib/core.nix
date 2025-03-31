{
  stdenv,
  # manually
  coreSrc,
  ...
}:

stdenv.mkDerivation {
  pname = "moonbit-core";
  version = coreSrc.shortRev;

  src = coreSrc;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/core
    cp -r ./source/* $out/lib/core
    runHook postInstall
  '';
}
