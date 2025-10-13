{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  nodejs,
  # manually
  version,
  url,
  hash,
  ...
}:

stdenv.mkDerivation {
  pname = "moonbit-cli";
  inherit version;

  src = fetchurl {
    inherit url;
    inherit hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libgcc
  ];

  installPhase =
    let
      mkInstall = bin: "install -m755 -D bin/${bin} $out/bin/${bin}";
      bins = [
        "moonfmt"
        "mooninfo"
        "mooncake"
        "moon"
        "moon_cove_report"
        "moonrun"
        "moonc"
        "moondoc"
        "moonbit-lsp"
      ];
      binsShell = lib.concatStringsSep "\n" (map mkInstall bins);
    in
    ''
      runHook preInstall
      ${binsShell}
      wrapProgram "$out/bin/moonbit-lsp" \
        --prefix PATH ":" ${lib.makeBinPath [ nodejs ]}
      runHook postInstall
    '';

  meta = {
    homepage = "moonbitlang.com";
    description = "TODO";
    mainProgram = "moon";
  };
}
