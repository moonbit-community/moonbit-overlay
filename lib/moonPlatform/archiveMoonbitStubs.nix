# Archive a package's compiled C-FFI stub `.o`s into a static `lib<pkg>.a`, which
# `makeMoonbitExecutable` then links. `$AR` is stdenv's wrapped archiver.
#
#   moonPlatform.archiveMoonbitStubs {
#     pname = "liba_b";
#     objs  = [ { drv = stubODrv; name = "a_b_0.o"; } ];
#   }
#   # → $out/liba_b.a
{
  lib,
  stdenv,
}:
{
  pname,
  objs ? [ ],
}:
let
  objArgs = map (o: "${o.drv}/${o.name}") objs;
in
stdenv.mkDerivation {
  name = pname;
  dontUnpack = true;
  phases = [ "buildPhase" ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    $AR -r -c -s $out/${pname}.a ${lib.escapeShellArgs objArgs}
    runHook postBuild
  '';
}
