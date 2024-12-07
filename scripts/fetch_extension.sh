#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#vsce nixpkgs#jq --command bash

extension="./versions/extension.nix"

versions_json=$(vsce show moonbit.moonbit-lang --json)
versions=($(echo $versions_json | jq ".versions.[].version" | sort -rV))

echo -e "\e[0;36m${#versions[@]} versions\e[0m" > /dev/stderr

fetch-extension-sha256() {
  version="$1"
  uri="https://moonbit.gallery.vsassets.io/_apis/public/gallery/publisher/moonbit/extension/moonbit-lang/${version:1:-1}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr

  hash=$(nix-hash --type sha256 --base64 --flat <(curl -o - $uri))
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

# clear content of extension file
: > $extension

echo "{" >> $extension

for v in "${versions[@]}"
do
  # drop any version lt "0.1.202410310"
  if [[ "$v" == '"0.1.202410310"' ]]; then
    break
  fi
  echo "appending $v" > /dev/stderr
  hash=$(fetch-extension-sha256 $v)
  echo "  $v = \"$hash\";" >> $extension
done

echo "}" >> $extension

git diff $extension

echo done > /dev/stderr
