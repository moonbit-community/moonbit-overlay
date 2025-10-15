#!/usr/bin/env bash

jq="nix run nixpkgs#jq --"
tomlq="nix shell nixpkgs#yq -c tomlq"
sednr="nix run nixpkgs#gnused -- -nr"

revision=${1:-$REVISION}
if [[ -z "$revision" ]]; then
  echo "Error: revision not specified and REVISION env variable not set." > /dev/stderr
  exit 1
fi

echo -e "\e[0;36mUpdating moon dependencies for revision \e[1;36m$revision\e[0m" > /dev/stderr

deps_versions_file="lib/moon-patched/deps_versions.json"
deps_versions=$(cat $deps_versions_file)

echo -e "\e[0;36mdownloading \e[4;36mCargo.lock\e[0;36m from moon repository...\e[0m" > /dev/stderr
cargo_lock=$(mktemp)
wget -q https://raw.githubusercontent.com/moonbitlang/moon/"$revision"/Cargo.lock -O "$cargo_lock"

fetch-sha256() {
  uri="$1"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr
  hash=$(nix-prefetch-url "$uri")
  hash=$(nix-hash --type sha256 --to-sri "$hash")
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr
  
  echo "$hash"
}

fetch-github-sha256() {
  owner="$1"
  repo="$2"
  rev="$3"
  echo -e "\e[0;36mfetching \e[4;36mhttps://github.com/$owner/$repo/archive/$rev.tar.gz\e[0;36m...\e[0m" > /dev/stderr
  hash=$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$rev.tar.gz")
  hash=$(nix-hash --type sha256 --to-sri "$hash")
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

# prefetch rusty_v8
echo -e "\e[0;36mprocessing \e[1;36mrusty_v8\e[0;36m dependency...\e[0m" > /dev/stderr
v8_version=$($tomlq --raw-output '.package[] | select(.name == "v8") | .version' "$cargo_lock")
echo -e "\e[0;36mv8 version: \e[1;36mv$v8_version\e[0m" > /dev/stderr

if [[ $(echo "$deps_versions" | $jq -r '."librusty_v8" | keys[] | contains("'"$v8_version"'")') == "true" ]]; then
  echo -e "\e[0;32minfo: librusty_v8 v$v8_version is already in deps_versions.json\e[0m" > /dev/stderr
else
  echo -e "\e[0;36mfetching librusty_v8 binaries for version \e[1;36mv$v8_version\e[0m" > /dev/stderr
  hashes_json="{}"
  for platform in x86_64-unknown-linux-gnu aarch64-apple-darwin; do
    echo -e "\e[0;36mprocessing platform: \e[1;36m$platform\e[0m" > /dev/stderr
    uri="https://github.com/denoland/rusty_v8/releases/download/v${v8_version}/librusty_v8_release_${platform}.a.gz"
    hash=$(fetch-sha256 "$uri")

    hashes_json=$(echo "$hashes_json" | jq '."'"$platform"'" = "'"$hash"'"')
  done

  deps_versions=$(echo "$deps_versions" | jq '."librusty_v8"."'"$v8_version"'" = '"$hashes_json"'')
  echo -e "\e[0;32msuccessfully updated librusty_v8 $v8_version\e[0m" > /dev/stderr
fi


# prefetch n2
echo -e "\e[0;36mprocessing \e[1;36mn2\e[0;36m dependency...\e[0m" > /dev/stderr
n2_version=$($tomlq --raw-output '.package[] | select(.name == "n2") | .version' "$cargo_lock")
n2_rev=$($tomlq --raw-output '.package[] | select(.name == "n2") | .source' "$cargo_lock" | $sednr 's|.*rev=(\w*)[^$].*|\1|p')
echo -e "\e[0;36mn2 version: \e[1;36mv$n2_version ($n2_rev)\e[0m" > /dev/stderr
if [[ $(echo "$deps_versions" | $jq -r '."n2" | keys[] | contains("'"$n2_rev"'")') == "true" ]]; then
  echo -e "\e[0;32minfo: n2 v$n2_version ($n2_rev) is already in deps_versions.json\e[0m" > /dev/stderr
else
  echo -e "\e[0;36mfetching n2 source for revision \e[1;36m$n2_rev\e[0m" > /dev/stderr
  hash=$(fetch-github-sha256 "moonbitlang" "n2" "$n2_rev")
  deps_versions=$(echo "$deps_versions" | jq '."n2"."'"$n2_rev"'" = "'"$hash"'"')
  echo -e "\e[0;32msuccessfully updated n2 $n2_rev\e[0m" > /dev/stderr
fi

echo -e "\e[0;36mwriting updated dependencies to \e[1;36m$deps_versions_file\e[0m" > /dev/stderr
echo "$deps_versions" | jq . > "$deps_versions_file"
echo -e "\e[0;32mdone\e[0m" > /dev/stderr
