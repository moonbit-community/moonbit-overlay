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

run_version=""
for target in linux-x86_64 darwin-aarch64; do # Keep the linux-x86_64 first
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
    # Run only once on linux-x86_64
    # assume that all `moonc` in different arches have the same version
    if [ -z "${run_version}" ]; then
      run_version=$(nix run .\#moonc -- -v)
    fi

    if [ -z "${run_version}" ]; then
      echo -e "error: failed get version from moonc" > /dev/stderr
      exit 1
    fi

    # remove the date suffix after the whitespace
    if [[ "$run_version" == *" "* ]]; then
      run_version="${run_version%% *}"
    fi
    echo -e "\e[0;36mcurrent version: \e[1;36m$run_version\e[0m" > /dev/stderr

    # update latest
    $sedi "s|version\": \".*\"|version\": \"$run_version\"|" $latest_file
    # re-fetch
    # NOTE: uri 'latest/moonbit.tar.gz' and
    #       uri '(latest moonc -v)/moonbit.tar.gz' are not same
    escaped_version=${run_version:1}
    escaped_version=${escaped_version//+/%2B}

    target_uri="$uri/binaries/$escaped_version/moonbit-$target.tar.gz"

    echo -e "\e[0;36mre-fetching\e[0m..." > /dev/stderr
    target_hash=$(fetch-sha256 $target_uri)

    $sedi "s|$target-cliHash\": \"sha256-.*\"|$target-cliHash\": \"sha256-$target_hash\"|" $latest_file

    echo -e "\e[0;36mfetching core\e[0m" > /dev/stderr
    target_hash=$(fetch-sha256 "$uri/cores/core-$escaped_version.tar.gz")
    $sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$target_hash\"|" $latest_file

    # pin
    cp $latest_file "$toolchains_dir/$run_version.json"
  fi
done

echo done > /dev/stderr
