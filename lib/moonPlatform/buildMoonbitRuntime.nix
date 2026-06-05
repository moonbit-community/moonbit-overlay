# Compile the MoonBit native runtime (`runtime.c`, shipped in the toolchain) into
# `runtime.o`, once per native executable. The C compiler comes from `stdenv`
# (`$CC` — the nixpkgs cc-wrapper, which resolves crt/libc correctly), the sources
# and headers from the `toolchain`.
#
#   moonPlatform.buildMoonbitRuntime { toolchain = …; }   # → $out/runtime.o
{
  stdenv,
}:
{
  pname ? "moonbit-runtime",
  toolchain,
}:
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    $CC -o $out/runtime.o -I${toolchain}/include -g -c -fwrapv -fno-strict-aliasing \
      -O2 -DMOONBIT_ALLOW_STACKTRACE -DMOONBIT_USE_SIMDUTF \
      ${toolchain}/lib/runtime.c
    runHook postBuild
  '';
}
