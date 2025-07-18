{
  pkgs,
  lib,
  moonbit-bin,
}:

let
  extensionsVersions = import ../versions/extension.nix;

  # TODO: libify
  escapeFrom = [
    "."
    "+"
  ];
  escapeTo = [
    "_"
    "-"
  ];
  chase = builtins.replaceStrings escapeTo escapeFrom;

  # TODO: pin `latest` version to specific version
  mkMLang =
    version: hash:
    pkgs.vscode-utils.extensionFromVscodeMarketplace {
      name = "moonbit-lang";
      publisher = "moonbit";
      inherit version;
      sha256 = hash;
    };
  mkMLsp =
    lang:
    pkgs.writeShellApplication {
      name = "moonbit-lsp";
      runtimeInputs = [ pkgs.nodejs ];
      runtimeEnv.MOON_HOME = "${moonbit-bin.moonbit.latest}";
      text = "node ${lang}/share/vscode/extensions/moonbit.moonbit-lang/node/lsp-server.js";
    };
in

{
  lsp = builtins.mapAttrs (version: hash: mkMLsp (mkMLang (chase version) hash)) extensionsVersions;
}
