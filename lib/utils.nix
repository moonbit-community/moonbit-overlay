{ lib, stdenv, ... }:
rec {
  moonbitUri = "https://cli.moonbitlang.com";
  target =
    {
      "x86_64-linux" = "linux-x86_64";
      "x86_64-darwin" = "darwin-x86_64";
      "aarch64-darwin" = "darwin-aarch64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  mkVersion = lib.escapeURL;
  latestVersion = (lib.importJSON ../versions/toolchains/latest.json).version;
  # TODO(jinser): Refactoring to less messy code
  # TODO(jinser): documentation somewhere
  mkCoreUri =
    version:
    let
      version' = if version == "latest" then latestVersion else version;
    in
    if version' == "updating" then
      "${moonbitUri}/cores/core-latest.tar.gz"
    else
      "https://github.com/moonbit-community/moonbit-overlay/releases/download/${mkVersion version'}/moonbit-core.tar.gz";
  mkToolChainsUri =
    version:
    let
      version' = if version == "latest" then latestVersion else version;
    in
    if version' == "updating" then
      "${moonbitUri}/binaries/latest/moonbit-${target}.tar.gz"
    else
      "https://github.com/moonbit-community/moonbit-overlay/releases/download/${mkVersion version'}/moonbit-${target}.tar.gz";
  escape =
    let
      escapeFrom = [
        "."
        "+"
      ];
      escapeTo = [
        "_"
        "-"
      ];
      escape = builtins.replaceStrings escapeFrom escapeTo;
    in
    escape;
}
