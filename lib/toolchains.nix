{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  tinycc,
  # manually
  version,
  url,
  hash,
  ...
}:
stdenv.mkDerivation {
  pname = "moonbit-toolchains";
  inherit version;

  src = fetchurl {
    inherit url;
    inherit hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libgcc
  ];

  installPhase =
    ''
      runHook preInstall

      mkdir -p $out
      cp -a ./* $out/
      chmod +x $out/bin/*
      chmod +x $out/bin/internal/tcc

    ''
    + lib.optionalString (version != "latest") ''
      rm $out/bin/internal/tcc
      ln -sf ${tinycc.out}/bin/tcc $out/bin/internal/tcc
    ''
    + ''

      runHook postInstall
    '';

  meta = {
    homepage = "moonbitlang.com";
    description = "TODO";
    mainProgram = "moon";
  };
}
