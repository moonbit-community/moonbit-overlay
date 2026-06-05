# Fine-grained MoonBit builder: compile ONE package into its `.core` (+ sibling
# `.mi`) as a standalone derivation, by driving `moonc build-package` directly.
#
# This is the per-package analogue of crate2nix's `buildRustCrate` / cargo2nix's
# `rustBuilder` — except it shells out to the compiler (`moonc`), not to `moon`.
# An external planner (e.g. `moon export-nix`) computes the package graph and
# emits one `buildMoonCore { … }` call per node, wiring dependencies through Nix
# derivation outputs. wasm-gc only for now (native drags nixpkgs C libraries and
# is handled by a separate builder).
#
#   moonPlatform.buildMoonCore {
#     pname = "a_b";                    # derivation name + artifact stem
#     pkg   = "a/b";                    # `-pkg` FQN
#     src   = ./a/b;                    # the package source directory
#     files = [ "x.mbt" "y.mbt" ];      # .mbt sources to compile (tests pre-filtered)
#     deps  = [ { core = otherDrv; name = "dep_stem"; alias = "dep"; } ];
#     toolchain = pkgs.moonbit-bin.moonbit.latest;   # bundled toolchain (moonc + core bundle)
#   }
#   # → $out/a_b.core, $out/a_b.mi
{
  lib,
  stdenv,
}:
{
  pname,
  pkg,
  src,
  files,
  isMain ? false,
  # [ { core = <drv>; name = "<stem>"; alias = "<import alias>"; } ]
  deps ? [ ],
  # standard-library sub-package imports provided by the bundle:
  # [ { sub = "immut/sorted_map"; last = "sorted_map"; alias = "sorted_map"; } ]
  stdImports ? [ ],
  target ? "wasm-gc",
  toolchain,
}:
let
  bundle = "${toolchain}/lib/core/_build/${target}/release/bundle";
  srcArgs = map (f: "${src}/${f}") files;
  depArgs = lib.concatMap (d: [ "-i" "${d.core}/${d.name}.mi:${d.alias}" ]) deps;
  stdArgs = lib.concatMap (s: [ "-i" "${bundle}/${s.sub}/${s.last}.mi:${s.alias}" ]) stdImports;
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = [ toolchain ];
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    moonc build-package ${lib.escapeShellArgs srcArgs} \
      -o $out/${pname}.core -pkg ${pkg} ${lib.optionalString isMain "-is-main"} \
      -std-path ${bundle} -i ${bundle}/prelude/prelude.mi:prelude \
      ${lib.escapeShellArgs (depArgs ++ stdArgs)} \
      -pkg-sources ${pkg}:${src} -target ${target}
    runHook postBuild
  '';
}
