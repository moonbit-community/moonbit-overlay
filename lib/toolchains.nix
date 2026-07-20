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

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a ./* $out/
    chmod +x $out/bin/*
    chmod +x $out/bin/internal/tcc

  ''
  # On Linux the bundled `internal/tcc` is an autopatched ELF that does not
  # work standalone, so we swap in nixpkgs `tinycc` and its matching runtime
  # helpers. On Darwin the bundled Mach-O `tcc` is what upstream ships and
  # uses, and nixpkgs `tinycc` is currently marked broken on aarch64-darwin
  # (see issue #40), so keep the bundled toolchain there. The boundary is the
  # platform, not the version.
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    rm $out/bin/internal/tcc
    ln -sf ${tinycc.out}/bin/tcc $out/bin/internal/tcc

    for helper in libtcc1.a runmain.o bcheck.o bt-exe.o bt-log.o; do
      rm -f "$out/lib/$helper"
      ln -s "${tinycc.lib}/lib/tcc/$helper" "$out/lib/$helper"
    done
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
