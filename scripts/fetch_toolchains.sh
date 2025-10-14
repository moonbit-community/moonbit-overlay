#!/usr/bin/env bash

toolchains_dir="./versions/toolchains"
latest_file="$toolchains_dir/latest.json"

sedi="nix run nixpkgs#gnused -- -i"
sednr="nix run nixpkgs#gnused -- -nr"

dash_to_underscore() {
    echo "$1" | tr '-' '_'
}

fetch-sha256() {
  uri="$1"
  name="$2"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr
  curl -o "$name" $uri
  hash=$(nix-hash --type sha256 --base64 --flat "$name")
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

  target_hash=$(fetch-sha256 $target_uri "moonbit-$target.tar.gz")

  old_version=$($sednr 's|^\s*"version\": \"(.*)\",$|\1|p' $latest_file)
  $sedi "s|version\": \".*\"|version\": \"latest\"|" $latest_file
  $sedi "s|$target-cliHash\": \"sha256-.*\"|$target-cliHash\": \"sha256-$target_hash\"|" $latest_file

  # phase 1

  if ! git diff --exit-code $latest_file; then
    echo -e "\e[0;36mfetching core\e[0m" > /dev/stderr
    target_hash=$(fetch-sha256 "$uri/cores/core-latest.tar.gz" "moonbit-core.tar.gz")
    $sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$target_hash\"|" $latest_file

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

    # skip if version not changed
    if [ "$run_version" == "$old_version" ]; then
      echo -e "\e[0;33mversion not changed ($run_version), skipping\e[0m" > /dev/stderr
      echo "skipped=true" >> "$GITHUB_OUTPUT"
      exit 0
    fi

    # update latest
    $sedi "s|version\": \".*\"|version\": \"$run_version\"|" $latest_file

    # pin
    cp $latest_file "$toolchains_dir/$run_version.json"

    # output version to action
    echo "version=$run_version" >> "$GITHUB_OUTPUT"
  fi
done

echo done > /dev/stderr
