# `zig translate-c` one toolchain C header (e.g. `moonbit.h`) into a Zig module,
# so a `.zig` native stub can `@import` the header's MACROS (which `extern` decls
# can't reach). The nix analogue of mymoon's `TranslateC` action. Output is the
# translated module at `$out/translated.zig`; `buildMoonbitZigStub` wires it as a
# `-M` module via `{ name; drv; }`.
#
#   moonPlatform.translateMoonbitCHeader { pname = "a_b_moonbit_tc"; header = "moonbit.h"; toolchain = …; }
#   # → $out/translated.zig
#
# Two sandbox-specific workarounds vs the bare `zig translate-c -lc` mymoon runs:
#  1. translate-c writes its cache output path relative to the CWD and fails with
#     `CacheCheckFailed` when the header lives in a read-only store dir (see
#     ziglang/translate-c#47, ziglang/zig#30025). So we copy the toolchain headers
#     into a writable dir and run from there with a RELATIVE header path.
#  2. `-lc`/`-target` make zig install+cache its own libc, which also trips
#     `CacheCheckFailed` in the pure sandbox. Instead we point `-I` at the stdenv
#     libc's headers so the header's `#include <math.h>` etc. resolve directly.
#
# TODO(revert-when-fixed): once translate-c#47 lands (output/cache paths resolved
# from the source dir, not the CWD), drop the copy+cd dance and the libc `-I` and
# just run `zig translate-c -lc -I${toolchain}/include ${toolchain}/include/${header}`.
# NB the libc `-I` is glibc-shaped via `stdenv.cc.libc`; if darwin needs a different
# header root this is the line to adjust.
{
  lib,
  stdenv,
  zig,
}:
{
  pname,
  header,
  toolchain,
}:
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out $TMPDIR/work
    export HOME=$TMPDIR
    cp -L ${toolchain}/include/*.h $TMPDIR/work/
    chmod -R u+w $TMPDIR/work
    cd $TMPDIR/work
    ${zig}/bin/zig translate-c \
      -I${lib.getDev stdenv.cc.libc}/include -I. \
      ${header} > $out/translated.zig
    runHook postBuild
  '';
}
