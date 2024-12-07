{ pkgs
, lib
, moonbit-bin
}:

let
  extensionsVersions = import ../versions/extension.nix;
  mkVersion = cli: "${builtins.substring 1 12 cli.version}0";
  versions = lib.filterAttrs
    (_: lib.flip builtins.hasAttr extensionsVersions)
    (builtins.mapAttrs (_: mkVersion) moonbit-bin.cli);

  mkMLang = version: pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "moonbit-lang";
    publisher = "moonbit";
    version = version;
    sha256 = extensionsVersions.${version};
  };
  mkMLsp = lang: pkgs.writeShellApplication {
    name = "moonbit-lsp";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      export MOON_HOME='${moonbit-bin.moonbit.latest}'
      node ${lang}/share/vscode/extensions/moonbit.moonbit-lang/node/lsp-server.js
    '';
  };
in

{
  lsp = builtins.mapAttrs (_: version: mkMLsp (mkMLang version)) versions;
}
