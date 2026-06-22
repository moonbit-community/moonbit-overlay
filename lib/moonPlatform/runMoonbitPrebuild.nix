# Fine-grained MoonBit pre-build (codegen) step: run ONE package's `pre-build`
# rule as a standalone derivation. The (already path-relativized) `command` runs
# in a working directory holding the rule's declared `inputs` (copied in by their
# package-relative path); the declared `outputs` are captured into `$out` under
# the same relative paths. A dependent `buildMoonbitPackage` then pulls each
# generated source via `generated = [ { drv = <this>; file = "<output>"; } ]`.
#
# `moon`'s built-in `:embed` lowers to `moon tool embed …`, so the toolchain is on
# PATH. Codegen that needs extra tools passes them via `buildInputs`.
#
#   moonPlatform.runMoonbitPrebuild {
#     pname   = "gen_a_b_x";
#     command = "moon tool embed --text -i hello.txt -o hello.mbt";
#     inputs  = [ { path = "hello.txt"; src = ./a/b/hello.txt; } ];
#     outputs = [ "hello.mbt" ];
#     toolchain = …;
#   }
#   # → $out/hello.mbt
{
  lib,
  stdenv,
}:
{
  pname,
  command,
  inputs ? [ ],
  outputs,
  # extra codegen tools (the build.rs / nativeBuildInputs analogue)
  buildInputs ? [ ],
  toolchain,
}:
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = [ toolchain ] ++ buildInputs;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    ${lib.concatMapStrings (i: ''
      mkdir -p "$(dirname ${lib.escapeShellArg i.path})"
      cp --no-preserve=mode,ownership ${i.src} ${lib.escapeShellArg i.path}
    '') inputs}
    ${command}
    ${lib.concatMapStrings (o: ''
      mkdir -p "$out/$(dirname ${lib.escapeShellArg o})"
      cp --no-preserve=mode,ownership ${lib.escapeShellArg o} "$out/${o}"
    '') outputs}
    runHook postBuild
  '';
}
