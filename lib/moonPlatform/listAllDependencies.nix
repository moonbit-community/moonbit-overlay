# List dependencies closure of dependencies in root moon.mod.json.
{ lib, parseMoonIndex }:
let

  # Returns attrset<name: string, index-entry: attrset>
  listAllDependencies =
    {
      registryIndexSrc,
      unresolvedDependencies, # list<{name: string, version: string}>
      resolvedDependencies ? { }, # attrset<name: string, version: string>
    }:
    if builtins.length unresolvedDependencies == 0 then
      [ ]
    else
      let
        head = builtins.head unresolvedDependencies;
        tail = builtins.tail unresolvedDependencies;
        headIndexRecords = builtins.readFile "${registryIndexSrc}/user/${head.name}.index";
        headIndex = parseMoonIndex headIndexRecords;
        headDependency = headIndex.${head.version};
        resolvedDependencies' = resolvedDependencies // {
          head.name = head.version;
        };
        unresolvedDependencies' =
          tail
          ++ (lib.mapAttrsToList (name: version: { inherit name version; }) (headDependency.deps or { }));
        next = listAllDependencies {
          inherit registryIndexSrc;
          unresolvedDependencies = unresolvedDependencies';
          resolvedDependencies = resolvedDependencies';
        };
      in
      if builtins.hasAttr head.name resolvedDependencies then next else next ++ [ headDependency ];
in
listAllDependencies
