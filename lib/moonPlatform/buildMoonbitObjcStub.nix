# Compile one Objective-C (`.m`) / Objective-C++ (`.mm`) native stub into a `.o`,
# for the native backend — the nix analogue of mymoon's `clang -x objective-c[++]`
# step. The object is archived + linked exactly like a C stub. Objective-C only
# compiles with clang (not stdenv's `$CC`, which is gcc on Linux), so we use clang
# explicitly; the language is pinned with `-x` rather than relying on extension
# sniffing. `cpp = true` selects Objective-C++ (`.mm`). Frameworks/libs are a
# LINK-time concern (the package's `stub-cc-link-flags`), not this compile step.
#
#   moonPlatform.buildMoonbitObjcStub { pname = "a_b_0"; stub = ./a/b/stub.m; toolchain = …; }
#   # → $out/a_b_0.o
{
  stdenv,
  clang,
}:
{
  pname,
  stub,
  toolchain,
  cpp ? false,
}:
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    ${clang}/bin/clang -o $out/${pname}.o -I${toolchain}/include -g -c \
      -fwrapv -fno-strict-aliasing -Og \
      -x ${if cpp then "objective-c++" else "objective-c"} ${stub}
    runHook postBuild
  '';
}
