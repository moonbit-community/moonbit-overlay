# Compile one C-FFI stub (`options("native-stub")`) into a `.o`, for the native
# backend. `$CC` is stdenv's cc-wrapper; `moonbit.h` comes from the toolchain.
#
#   moonPlatform.buildMoonbitCStub { pname = "a_b_0"; stub = ./a/b/stub.c; toolchain = …; }
#   # → $out/a_b_0.o
{
  stdenv,
}:
{
  pname,
  stub,
  toolchain,
}:
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    $CC -o $out/${pname}.o -I${toolchain}/include -g -c -fwrapv -fno-strict-aliasing \
      -Og ${stub}
    runHook postBuild
  '';
}
