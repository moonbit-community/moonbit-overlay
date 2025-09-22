{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  libgcc,
  # manually
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
  ];

  buildInputs = [
    libgcc
  ];

  installPhase = ''
    runHook preInstall
    cp -r . $out
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
