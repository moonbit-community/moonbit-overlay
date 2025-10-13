{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  nodejs,
  # manually
  moon-patched,
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
        "moon_cove_report"
        "moonc"
        "moondoc"
        "moonbit-lsp"
      ]
      ++ (
        if version == "latest" then
          [
            "moon"
            "moonrun"
          ]
        else
          [ ]
      );
      binsShell = lib.concatStringsSep "\n" (map mkInstall bins);
    in
    ''
      runHook preInstall
      ${binsShell}

    ''
    + lib.optionalString (version != "latest") ''
      install -m755 -D ${moon-patched}/bin/moon $out/bin/moon
      install -m755 -D ${moon-patched}/bin/moonrun $out/bin/moonrun
    ''
    + ''

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
