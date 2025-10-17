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
  curl -o "$name" "$uri"
  hash=$(nix-hash --type sha256 --base64 --flat "$name")
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

fetch-github-sha256() {
  owner="$1"
  repo="$2"
  rev="$3"
  echo -e "\e[0;36mfetching \e[4;36mhttps://github.com/$owner/$repo/archive/$rev.tar.gz\e[0;36m...\e[0m" > /dev/stderr
  hash=$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$rev.tar.gz")
  hash=$(nix-hash --to-base64 --type sha256 "$hash")
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

run_version=""
old_version=$($sednr 's|^\s*"version\": \"(.*)\",$|\1|p' $latest_file)
for target in linux-x86_64 darwin-aarch64; do # Keep the linux-x86_64 first
  target_uri="$(dash_to_underscore $target)_toolchains_uri"
  target_hash="$(dash_to_underscore $target)_toolchainsHash"
  # phase 0
  uri="https://cli.moonbitlang.com"

  target_uri="$uri/binaries/latest/moonbit-$target.tar.gz"

  target_hash=$(fetch-sha256 $target_uri "moonbit-$target.tar.gz")

  $sedi "s|version\": \".*\"|version\": \"updating\"|" $latest_file
  $sedi "s|$target-toolchainsHash\": \"sha256-.*\"|$target-toolchainsHash\": \"sha256-$target_hash\"|" $latest_file

  # phase 1

  if ! git diff --exit-code $latest_file; then
    echo -e "\e[0;36mfetching core\e[0m" > /dev/stderr
    target_hash=$(fetch-sha256 "$uri/cores/core-latest.tar.gz" "moonbit-core.tar.gz")
    $sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$target_hash\"|" $latest_file

    # Run only once on linux-x86_64
    # assume that all `moonc` and `moon` in different arches have the same version
    if [ -z "${run_version}" ] || [ -z "${moon_version}" ]; then
      run_version=$(nix run .\#moonc -- -v)
      moon_version=$(nix run .\#moon version)
    fi

    if [ -z "${run_version}" ] || [ -z "${moon_version}" ]; then
      echo -e "error: failed get version from toolchain" > /dev/stderr
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

    echo -e "\e[0;36mfetching core\e[0m" > /dev/stderr
    target_hash=$(fetch-sha256 "$uri/cores/core-latest.tar.gz" "moonbit-core.tar.gz")
    $sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$target_hash\"|" $latest_file

    # update moon version
    short_rev=$(echo "$moon_version" | sed -r 's/.*\((.*) .*\)/\1/')
    $sedi "s|moonRev\": \".*\"|moonRev\": \"$short_rev\"|" $latest_file

    moon_hash=$(fetch-github-sha256 "moonbitlang" "moon" "$short_rev")
    $sedi "s|moonHash\": \"sha256-.*\"|moonHash\": \"sha256-$moon_hash\"|" $latest_file

    echo "moon_revision=$short_rev" >> "$GITHUB_OUTPUT"

    # pin
    cp $latest_file "$toolchains_dir/$run_version.json"

    # output version to action
    echo "version=$run_version" >> "$GITHUB_OUTPUT"
  fi
done

echo "done" > /dev/stderr
