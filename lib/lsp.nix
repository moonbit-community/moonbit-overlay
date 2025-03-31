{
  pkgs,
  lib,
  moonbit-bin,
}:

let
  extensionsVersions = import ../versions/extension.nix;

  mkMLang =
    version:
    pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "moonbit-lang";
      publisher = "moonbit";
      version = version;
      sha256 = extensionsVersions.${version};
    };
  mkMLsp =
    lang:
    pkgs.writeShellApplication {
      name = "moonbit-lsp";
      runtimeInputs = [ pkgs.nodejs ];
      text = ''
        export MOON_HOME='${moonbit-bin.moonbit.latest}'
        node ${lang}/share/vscode/extensions/moonbit.moonbit-lang/node/lsp-server.js
      '';
    };
in

{
  lsp = builtins.mapAttrs (version: hash: mkMLsp (mkMLang version hash)) extensionsVersions;
}
