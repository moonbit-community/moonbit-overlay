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
  src = fetchFromGitHub {
    owner = "moonbitlang";
    repo = "moon";
    inherit rev hash;
  };

  cargoLockContents = lib.importTOML "${src}/Cargo.lock";
  librusty_v8_version = (lib.findFirst (x: x.name == "v8") { } cargoLockContents.package).version;
  n2_version = (lib.findFirst (x: x.name == "n2") { } cargoLockContents.package).version;
  n2_source = (lib.findFirst (x: x.name == "n2") { } cargoLockContents.package).source;
  n2_rev = lib.substring 0 40 (lib.elemAt (lib.splitString "rev=" n2_source) 1);

  deps_versions = lib.importJSON ./deps_versions.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "moonbit-cli";
  version = lib.substring 0 7 finalAttrs.src.rev;

  inherit src;
  env.VERGEN_GIT_SHA = finalAttrs.version;

  cargoLock = {
    lockFile = "${finalAttrs.src}/Cargo.lock";
    outputHashes = {
      "n2-${n2_version}" = deps_versions.n2."${n2_rev}";
    };
  };
  rustyV8 = fetchurl {
    name = "librusty_v8";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${librusty_v8_version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    hash = deps_versions.librusty_v8.${librusty_v8_version}.${stdenv.hostPlatform.rust.rustcTarget};
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
