# Link a set of `.core`s (a package and its dependency closure, dependencies
# first) into the final wasm-gc artifact, via `moonc link-core`. The companion to
# [buildMoonCore]; the standard-library `abort.core` / `core.core` are pulled from
# the toolchain bundle automatically.
#
#   moonPlatform.linkMoonCore {
#     pname = "a_b";
#     main  = "a/b";                                   # `-main` entry FQN
#     cores = [ { core = depDrv; name = "dep_stem"; }  # deps first …
#               { core = ownDrv; name = "a_b"; } ];    # … own core last
#     toolchain = pkgs.moonbit-bin.moonbit.latest;
#   }
#   # → $out/a_b.wasm
{
  lib,
  stdenv,
}:
{
  pname,
  main,
  # ordered (dependencies first): [ { core = <drv>; name = "<stem>"; } ]
  cores ? [ ],
  # source-location mapping (optional): [ { pkg = "a/b"; src = <path>; } ]
  pkgSources ? [ ],
  target ? "wasm-gc",
  toolchain,
}:
let
  bundle = "${toolchain}/lib/core/_build/${target}/release/bundle";
  coreArgs = map (c: "${c.core}/${c.name}.core") cores;
  pkgSrcArgs = lib.concatMap (p: [ "-pkg-sources" "${p.pkg}:${p.src}" ]) pkgSources;
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = [ toolchain ];
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    moonc link-core ${bundle}/abort/abort.core ${bundle}/core.core \
      ${lib.escapeShellArgs coreArgs} \
      -main ${main} -o $out/${pname}.wasm \
      ${lib.escapeShellArgs pkgSrcArgs} \
      -pkg-sources moonbitlang/core:${toolchain}/lib/core \
      -target ${target}
    runHook postBuild
  '';
}
