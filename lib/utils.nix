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

  mkVersion = v: lib.escapeURL (lib.removePrefix "v" v);
  mkCliUri = version: "${moonbitUri}/binaries/${mkVersion version}/moonbit-${target}.tar.gz";
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
