# Compile the MoonBit native runtime (`runtime.c`, shipped in the toolchain) into
# `runtime.o`, once per native executable. The C compiler comes from `stdenv`
# (`$CC` — the nixpkgs cc-wrapper, which resolves crt/libc correctly), the sources
# and headers from the `toolchain`.
#
#   moonPlatform.buildMoonbitRuntime { toolchain = …; }   # → $out/runtime.o
{
  stdenv,
  zig,
}:
{
  pname ? "moonbit-runtime",
  # Cross-compile: a zig target triple (e.g. "x86_64-windows-gnu"). When set,
  # compile `runtime.c` with `zig cc -target` and DROP the simdutf/stacktrace
  # defines — the target links neither (their build-arch objects are gated off in
  # `makeMoonbitExecutable`), so the runtime must not reference their symbols.
  crossTarget ? null,
  toolchain,
}:
let
  cc = if crossTarget == null then "$CC" else "${zig}/bin/zig cc -target ${crossTarget}";
  defines = if crossTarget == null then "-DMOONBIT_ALLOW_STACKTRACE -DMOONBIT_USE_SIMDUTF" else "";
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    export HOME=$TMPDIR
    ${cc} -o $out/runtime.o -I${toolchain}/include -g -c -fwrapv -fno-strict-aliasing \
      -O2 ${defines} \
      ${toolchain}/lib/runtime.c
    runHook postBuild
  '';
}
