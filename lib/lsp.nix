{
  pkgs,
  # manually
  version,
  bundle,
}:
pkgs.stdenv.mkDerivation {
  pname = "moonbit-lsp";
  inherit version;

  src = pkgs.emptyDirectory;

  buildInputs = [ pkgs.nodejs ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/bin
    cp ${bundle}/bin/.moonbit-lsp-orig $out/bin/moonbit-lsp
    sed -i '/#!\/usr\/bin\/env node/a process.env.MOON_HOME = "${bundle}";' $out/bin/moonbit-lsp
    sed -i '1s|#!/usr/bin/env node|#!${pkgs.nodejs}/bin/node|' $out/bin/moonbit-lsp
    chmod +x $out/bin/moonbit-lsp
    runHook postBuild
  '';
}
