{ stdenv
, fetchurl
  # manually
, version
, url
, hash
, ...
}:

stdenv.mkDerivation {
  pname = "moonbit-core";
  inherit version;

  src = fetchurl {
    inherit url;
    inherit hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp -r core $out/lib
    runHook postInstall
  '';
}
