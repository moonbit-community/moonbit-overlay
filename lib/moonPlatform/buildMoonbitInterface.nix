# Fine-grained MoonBit builder: generate a VIRTUAL package's interface `.mi`
# from its hand-written `.mbti` contract, via `moonc build-interface`. The
# companion to [buildMoonbitPackage]: a virtual package's `.mi` is produced HERE
# (not as a `build-package` sibling); consumers import it exactly like any
# dependency's `.mi`, and the package's optional default-impl `.core` is a
# separate `buildMoonbitPackage { noMi = true; … }` call.
#
#   moonPlatform.buildMoonbitInterface {
#     pname = "a_logger";                  # derivation name + artifact stem
#     pkg   = "a/logger";                  # `-pkg` FQN
#     src   = ./a/logger;                  # the package source directory
#     mbti  = "pkg.mbti";                  # the contract file, package-relative
#     deps  = [ { core = otherDrv; name = "dep_stem"; alias = "dep"; } ];
#     toolchain = pkgs.moonbit-bin.moonbit.latest;
#   }
#   # → $out/a_logger.mi
{
  lib,
  stdenv,
}:
{
  pname,
  pkg,
  src,
  mbti,
  # interface dependencies: [ { core = <drv>; name = "<stem>"; alias = "<import alias>"; } ]
  deps ? [ ],
  target ? "wasm-gc",
  toolchain,
}:
let
  bundle = "${toolchain}/lib/core/_build/${target}/release/bundle";
  depArgs = lib.concatMap (d: [ "-i" "${d.core}/${d.name}.mi:${d.alias}" ]) deps;
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  nativeBuildInputs = [ toolchain ];
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    moonc build-interface ${src}/${mbti} -o $out/${pname}.mi \
      ${lib.escapeShellArgs depArgs} \
      -pkg ${pkg} -pkg-sources ${pkg}:${src} -virtual -std-path ${bundle}
    runHook postBuild
  '';
}
