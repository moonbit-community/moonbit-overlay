#!/usr/bin/env bash

fetch-sha256() {
  uri="$1"
  hash=$(nix-hash --type sha256 --base64 --flat <(curl -o - $uri))

  echo "$hash"
}

uri=$(cat ./uri.txt)
cli_uri="$uri/binaries/latest/moonbit-linux-x86_64.tar.gz"
core_uri="$uri/cores/core-latest.tar.gz";

cli_hash=$(fetch-sha256 $cli_uri)
core_hash=$(fetch-sha256 $core_uri)

echo $cli_hash
echo $core_hash

sed -i "s|cliHash\": \"sha256-.*\"|cliHash\": \"sha256-$cli_hash\"|" ./versions/latest.json
sed -i "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$core_hash\"|" ./versions/latest.json
