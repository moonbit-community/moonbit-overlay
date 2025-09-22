{
  stdenv,
  fetchurl,
  # manually
  version,
  url,
  hash,
  ...
}:

stdenv.mkDerivation {
  pname = "moonbit-core";
  inherit version;

  src = fetchurl {
    inherit url;
    inherit hash;
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/core
    cp -r ./* $out/lib/core
    runHook postInstall
  '';
}