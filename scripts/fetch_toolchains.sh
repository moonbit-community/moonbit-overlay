#!/usr/bin/env bash

toolchains_dir="./versions/toolchains"
latest_file="$toolchains_dir/latest.json"

fetch-sha256() {
  uri="$1"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr

  hash=$(nix-hash --type sha256 --base64 --flat <(curl -o - $uri))
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

# phase 0

uri="https://cli.moonbitlang.com"
cli_uri="$uri/binaries/latest/moonbit-linux-x86_64.tar.gz"

cli_hash=$(fetch-sha256 $cli_uri)

sed -i "s|version\": \".*\"|version\": \"latest\"|" $latest_file
sed -i "s|cliHash\": \"sha256-.*\"|cliHash\": \"sha256-$cli_hash\"|" $latest_file

# phase 1

if ! git diff --exit-code $latest_file; then
  version=$(nix run .\#moonc -- -v)
  if [ -z "${version}" ]; then
    echo -e "error: failed get version from moonc" > /dev/stderr
    exit 1
  fi
  echo -e "\e[0;36mcurrent version: \e[1;36m$version\e[0m" > /dev/stderr

  # update latest
  sed -i "s|version\": \".*\"|version\": \"$version\"|" $latest_file
  # re-fetch
  # NOTE: uri 'latest/moonbit.tar.gz' and
  #       uri '(latest moonc -v)/moonbit.tar.gz' are not same
  escaped_version=${version:1}
  escaped_version=${escaped_version//+/%2B}
  cli_uri="$uri/binaries/$escaped_version/moonbit-linux-x86_64.tar.gz"
  echo -e "\e[0;36mre-fetching\e[0m..." > /dev/stderr
  cli_hash=$(fetch-sha256 $cli_uri)
  sed -i "s|cliHash\": \"sha256-.*\"|cliHash\": \"sha256-$cli_hash\"|" $latest_file
  # pin
  cp $latest_file "$toolchains_dir/$version.json"
fi

echo done > /dev/stderr
