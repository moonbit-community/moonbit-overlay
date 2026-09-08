lib:

let
  mkWarning = _: msg: lib.warnOnInstantiate msg dontBuildMe;
  dontBuildMe = derivation {
    name = "dontBuildMe";
    builder = "dontBuildMe";
    system = "dontBuildMe";
  };
in
builtins.mapAttrs mkWarning {
  lsp = ''
    'lsp' is deprecated and has been removed.
    The moonbit-bin.moonbit.<version> package includes the language server.
    With current toolchains, invoke moon-lsp directly (not moon lsp).
    For more information, see: https://github.com/moonbit-community/moonbit-overlay/pull/14
  '';
}
