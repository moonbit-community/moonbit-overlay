{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  # manually
  moon-patched,
  version,
  url,
  hash,
  ...
}:
stdenv.mkDerivation {
  pname = "moonbit-cli";
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

  installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -a ./* $out/

    ''
    + lib.optionalString (version != "latest") ''
      cp ${moon-patched}/bin/moon $out/bin/moon
      cp ${moon-patched}/bin/moonrun $out/bin/moonrun
    ''
    + ''

      chmod +x $out/bin/*
      chmod +x $out/bin/internal/tcc

      runHook postInstall
    '';

  meta = {
    homepage = "moonbitlang.com";
    description = "TODO";
    mainProgram = "moon";
  };
}
