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
#     pkgConfig = [ "zlib" ]; # native deps from `options("pkg-config")` — `--libs`
#     buildInputs = [ pkgs.zlib ];  # the corresponding nixpkgs libraries
#     toolchain = …;
#   }
#   # → $out/a_b   (an executable)
{
  lib,
  stdenv,
  pkg-config,
  zig,
}:
{
  pname,
  programC,
  runtime,
  stubArchives ? [ ],
  # `options("pkg-config")` native deps: the module names whose `--libs` join the
  # link, plus the nixpkgs libraries that provide them (so pkg-config — run IN the
  # sandbox via the setup hook's PKG_CONFIG_PATH — resolves them purely). Both
  # default empty ⇒ the link is unchanged (backward-compatible).
  pkgConfig ? [ ],
  buildInputs ? [ ],
  # Cross-compile: a zig target triple (e.g. "x86_64-windows-gnu"). When set, link
  # with `zig cc -target` instead of stdenv's `$CC`, and DROP the build-arch
  # prebuilt toolchain objects (simdutf/libbacktrace) — they are gated off for a
  # cross target exactly as in mymoon's own native link. `null` ⇒ a host build.
  crossTarget ? null,
  toolchain,
}:
let
  stubArgs = map (a: "${a.drv}/${a.name}") stubArchives;
  pkgCfgLibs = lib.optionalString (pkgConfig != [ ]) "$(pkg-config --libs ${lib.escapeShellArgs pkgConfig})";
  cc = if crossTarget == null then "$CC" else "${zig}/bin/zig cc -target ${crossTarget}";
  # Host: link the prebuilt simdutf + libbacktrace (+ libm). Cross: none of these
  # build-arch objects exist for the target — link only libm (the target libc's).
  tailObjs =
    if crossTarget == null then
      "${toolchain}/lib/moonbit_simdutf.o ${toolchain}/lib/simdutf.o -lm ${toolchain}/lib/libbacktrace.a"
    else
      "-lm";
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = lib.optional (pkgConfig != [ ]) pkg-config;
  inherit buildInputs;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    export HOME=$TMPDIR
    ${cc} -o $out/${pname} -I${toolchain}/include -g -fwrapv -fno-strict-aliasing -Og \
      ${programC}/${pname}.c ${runtime}/runtime.o \
      ${lib.escapeShellArgs stubArgs} \
      ${pkgCfgLibs} \
      ${tailObjs}
    runHook postBuild
  '';
}
