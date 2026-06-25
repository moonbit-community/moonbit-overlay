# Compile one Zig native stub (`native-stub` entry ending in `.zig`) into a `.o`,
# for the native backend — the nix analogue of mymoon's `zig build-obj` step. The
# object is archived + linked exactly like a C stub. `moonbit.h` comes from the
# toolchain; `-O ReleaseFast` keeps the object free of Zig's safety panic-handler
# references (the moonbit runtime, not Zig std, provides the symbols), and `-fPIC`
# lets it link into moonbit's PIE-by-default executable. `-lc` declares the libc
# dependency the stub already has (the moonbit binary links libc) so `std`'s
# libc-backed pieces — e.g. `std.heap.c_allocator` — pass their compile-time link
# gate; it only sets the dependency flag, the actual libc link still happens once,
# in the final executable. (Mirrors mymoon's own `zig build-obj` render.)
#
#   moonPlatform.buildMoonbitZigStub { pname = "a_b_0"; stub = ./a/b/stub.zig; toolchain = …; }
#   # → $out/a_b_0.o
#
# `modules` (default `[]`) are translate-c'd headers the stub `@import`s, as
# `{ name; drv; }` pairs (drv = a `translateMoonbitCHeader` derivation, output at
# `$out/translated.zig`). When non-empty the build switches to the explicit module
# form — `--dep <name> -Mmain=<stub> -M<name>=<drv>/translated.zig` — because the
# bare positional-file form can't carry import deps. Mirrors mymoon's bare render.
{
  lib,
  stdenv,
  zig,
  pkg-config,
}:
{
  pname,
  stub,
  toolchain,
  modules ? [ ],
  # `options("pkg-config")` native deps: the module names whose `--cflags` (header
  # search paths) join this stub's zig compile, plus the nixpkgs libraries providing
  # them. Both default empty ⇒ the compile is unchanged (backward-compatible).
  pkgConfig ? [ ],
  buildInputs ? [ ],
  # Cross-compile: a zig target triple. When set, `zig build-obj -target` it.
  crossTarget ? null,
}:
let
  moduleArgs =
    lib.concatMapStringsSep " " (m: "--dep ${m.name}") modules
    + " -Mmain=${stub} "
    + lib.concatMapStringsSep " " (m: "-M${m.name}=${m.drv}/translated.zig") modules;
  stubArg = if modules == [ ] then "${stub}" else moduleArgs;
  pkgCfgCflags = lib.optionalString (pkgConfig != [ ]) "$(pkg-config --cflags ${lib.escapeShellArgs pkgConfig})";
  targetArg = lib.optionalString (crossTarget != null) "-target ${crossTarget}";
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = lib.optional (pkgConfig != [ ]) pkg-config;
  inherit buildInputs;
  phases = [ "buildPhase" ];
  # Zig wants a writable cache dir (HOME/.cache) even for `build-obj`.
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    export HOME=$TMPDIR
    ${zig}/bin/zig build-obj -femit-bin=$out/${pname}.o -O ReleaseFast -fPIC -lc \
      ${targetArg} -I${toolchain}/include ${pkgCfgCflags} ${stubArg}
    runHook postBuild
  '';
}
