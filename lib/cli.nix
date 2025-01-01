{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  libgcc,
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
      ];
      binsShell = lib.concatStringsSep "\n" (map mkInstall bins);
    in
    ''
      runHook preInstall
      ${binsShell}
      runHook postInstall
    '';

  meta = {
    homepage = "moonbitlang.com";
    description = "TODO";
    mainProgram = "moon";
  };
}
