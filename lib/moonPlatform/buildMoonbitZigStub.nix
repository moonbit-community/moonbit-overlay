# Compile one Zig native stub (`native-stub` entry ending in `.zig`) into a `.o`,
# for the native backend — the nix analogue of mymoon's `zig build-obj` step. The
# object is archived + linked exactly like a C stub. `moonbit.h` comes from the
# toolchain; `-O ReleaseFast` keeps the object free of Zig's safety panic-handler
# references (the moonbit runtime, not Zig std, provides the symbols), and `-fPIC`
# lets it link into moonbit's PIE-by-default executable.
#
#   moonPlatform.buildMoonbitZigStub { pname = "a_b_0"; stub = ./a/b/stub.zig; toolchain = …; }
#   # → $out/a_b_0.o
{
  stdenv,
  zig,
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
  # Zig wants a writable cache dir (HOME/.cache) even for `build-obj`.
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    export HOME=$TMPDIR
    ${zig}/bin/zig build-obj -femit-bin=$out/${pname}.o -O ReleaseFast -fPIC \
      -I${toolchain}/include ${stub}
    runHook postBuild
  '';
}
