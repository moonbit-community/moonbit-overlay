# Parse $MOON_HOME/registry/index/user/<user>/<package>.index file
# into attrset<version: string, index-entry: attrset>.
{ lib }:
let
  parseMoonIndex =
    records:
    let
      recordsVecStrWithEmpty = lib.strings.splitString "\n" records;
      recordsVecStr = lib.lists.filter (s: s != "") recordsVecStrWithEmpty;
      recordsVecAttrset = builtins.map (record: builtins.fromJSON record) recordsVecStr;
      versionToRecord = builtins.listToAttrs (
        builtins.map (record: {
          name = record.version;
          value = record;
        }) recordsVecAttrset
      );
    in
    versionToRecord;
in
parseMoonIndex
