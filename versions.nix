lib:

let
  verExt = ".json";
  ver = name: lib.importJSON (./versions/${name}${verExt});
  allVers = with lib;
    mapAttrsToList
      (n: _: removeSuffix verExt n)
      (filterAttrs
        (n: v: v == "regular" || hasSuffix verExt n)
        (builtins.readDir ./versions));
in
lib.genAttrs allVers ver
