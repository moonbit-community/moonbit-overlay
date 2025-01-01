#!/usr/bin/env bash

toolchains_dir="./versions/toolchains"
latest_file="$toolchains_dir/latest.json"

sedi="nix run nixpkgs#gnused -- -i"

dash_to_underscore() {
    echo "$1" | tr '-' '_'
}

fetch-sha256() {
  uri="$1"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr
  touch temp
  curl -o- $uri > temp
  hash=$(nix-hash --type sha256 --base64 --flat temp)
  rm temp
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

for target in linux-x86_64 darwin-aarch64; do
  target_uri="$(dash_to_underscore $target)_cli_uri"
  target_hash="$(dash_to_underscore $target)_cliHash"
  # phase 0
  uri="https://cli.moonbitlang.com"

  target_uri="$uri/binaries/latest/moonbit-$target.tar.gz"

  target_hash=$(fetch-sha256 $target_uri)

  $sedi "s|version\": \".*\"|version\": \"latest\"|" $latest_file
  $sedi "s|$target-cliHash\": \"sha256-.*\"|$target-cliHash\": \"sha256-$target_hash\"|" $latest_file

  # phase 1

  if ! git diff --exit-code $latest_file; then
    version=$(nix run .\#moonc -- -v)
    if [ -z "${version}" ]; then
      echo -e "error: failed get version from moonc" > /dev/stderr
      exit 1
    fi
    echo -e "\e[0;36mcurrent version: \e[1;36m$version\e[0m" > /dev/stderr

    # update latest
    $sedi "s|version\": \".*\"|version\": \"$version\"|" $latest_file
    # re-fetch
    # NOTE: uri 'latest/moonbit.tar.gz' and
    #       uri '(latest moonc -v)/moonbit.tar.gz' are not same
    escaped_version=${version:1}
    escaped_version=${escaped_version//+/%2B}

    target_uri="$uri/binaries/$escaped_version/moonbit-$target.tar.gz"

    echo -e "\e[0;36mre-fetching\e[0m..." > /dev/stderr
    target_hash=$(fetch-sha256 $target_uri)

    $sedi "s|$target-cliHash\": \"sha256-.*\"|$target-cliHash\": \"sha256-$target_hash\"|" $latest_file
    # pin
    cp $latest_file "$toolchains_dir/$version.json"
  fi
done

echo done > /dev/stderr
