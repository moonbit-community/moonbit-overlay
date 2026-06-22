# `cc`-link a native MoonBit program: the `link-core`-emitted `.c` + the compiled
# runtime + any C-stub archives + the toolchain's simdutf objects + libbacktrace
# (+ libm) into the final executable. The companion to [linkMoonbitProgram] (with
# `target = "native"`) and [buildMoonbitRuntime].
#
#   moonPlatform.makeMoonbitExecutable {
#     pname    = "a_b";
#     programC = cDrv;        # linkMoonbitProgram { target = "native"; } → $out/a_b.c
#     runtime  = runtimeDrv;  # buildMoonbitRuntime → $out/runtime.o
#     stubArchives = [ ];     # [ { drv = …; name = "lib<pkg>.a"; } ] (C-FFI packages)
#     toolchain = …;
#   }
#   # → $out/a_b   (an executable)
{
  lib,
  stdenv,
}:
{
  pname,
  programC,
  runtime,
  stubArchives ? [ ],
  toolchain,
}:
let
  stubArgs = map (a: "${a.drv}/${a.name}") stubArchives;
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    $CC -o $out/${pname} -I${toolchain}/include -g -fwrapv -fno-strict-aliasing -Og \
      ${programC}/${pname}.c ${runtime}/runtime.o \
      ${lib.escapeShellArgs stubArgs} \
      ${toolchain}/lib/moonbit_simdutf.o ${toolchain}/lib/simdutf.o \
      -lm ${toolchain}/lib/libbacktrace.a
    runHook postBuild
  '';
}
