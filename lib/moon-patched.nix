{
  lib,
  perl,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  # manually
  rev,
  hash,
}:
let
  rustyV8Attr = {
    "x86_64-linux" = {
      name = "librusty_v8_release_x86_64-unknown-linux-gnu.a";
      url = "https://github.com/denoland/rusty_v8/releases/download/v0.106.0/librusty_v8_release_x86_64-unknown-linux-gnu.a.gz";
      hash = "sha256-f7V60F69XsRhgwg34K9TFWruelVuux7MKpLG5vlV7Oc=";
    };
    "aarch64-darwin" = {
      name = "librusty_v8_release_aarch64-apple-darwin.a";
      url = "https://github.com/denoland/rusty_v8/releases/download/v0.106.0/librusty_v8_release_aarch64-apple-darwin.a.gz";
      hash = "3Smt9CqdZBqdHga9O/Y66/S2AzwdLjvq4KNK11Xw4ac=";
    };
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "moonbit-cli";
  version = lib.substring 0 7 finalAttrs.src.rev;

  src = fetchFromGitHub {
    owner = "moonbitlang";
    repo = "moon";
    inherit rev hash;
  };
  env.VERGEN_GIT_SHA = finalAttrs.version;

  cargoLock = {
    lockFile = "${finalAttrs.src}/Cargo.lock";
    outputHashes = {
      "n2-0.1.5" = "sha256-DGixqPGqasiXdoRlpuJUYNOyVLHP/yVBkYt+Dhhe6Zk=";
    };
  };
  rustyV8 = fetchurl rustyV8Attr.${stdenv.hostPlatform.system} // {
    downloadToTemp = true;
    postFetch = "gzip -cd $downloadedFile > $out";
  };
  env.RUSTY_V8_ARCHIVE = "${finalAttrs.rustyV8}";

  nativeBuildInputs = [
    perl
  ];

  patches = [
    ./moon-nix.patch
  ];

  doCheck = false;
})
