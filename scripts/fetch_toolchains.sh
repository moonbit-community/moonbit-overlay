#!/usr/bin/env bash

toolchains_dir="./versions/toolchains"
latest_file="$toolchains_dir/latest.json"
nightly_file="$toolchains_dir/nightly.json"
uri="https://cli.moonbitlang.com"
nightly_artifacts="./nightly-artifacts"

rm -rf "$nightly_artifacts"
mkdir -p "$nightly_artifacts"

sedi="nix run nixpkgs#gnused -- -i"
sednr="nix run nixpkgs#gnused -- -nr"

dash_to_underscore() {
    echo "$1" | tr '-' '_'
}

fetch-sha256() {
  uri="$1"
  name="$2"
  echo -e "\e[0;36mfetching \e[4;36m$uri\e[0;36m...\e[0m" > /dev/stderr
  curl --fail --location --retry 3 -o "$name" "$uri"
  hash=$(nix-hash --type sha256 --base64 --flat "$name")
  echo -e "\e[0;36mcalculated hash: \e[1;36m$hash\e[0m" > /dev/stderr

  echo "$hash"
}

# ---------------------------------------------------------------------------
# nightly channel (dated archive)
#
# Upstream only retains the current nightly. Preserve every changed snapshot in
# an immutable GitHub release and keep nightly.json as an alias to the newest
# dated archive. A same-day rerun with different contents fails rather than
# silently changing an already published immutable release.
# ---------------------------------------------------------------------------
echo -e "\e[0;36mfetching nightly toolchains\e[0m" > /dev/stderr
old_nightly_version=$($sednr 's|^\s*"version": "(.*)",$|\1|p' $nightly_file)
for target in linux-x86_64 darwin-aarch64; do
  nightly_uri="$uri/binaries/nightly/moonbit-$target.tar.gz"
  nightly_hash=$(fetch-sha256 "$nightly_uri" "$nightly_artifacts/moonbit-$target.tar.gz")
  $sedi "s|$target-toolchainsHash\": \"sha256-.*\"|$target-toolchainsHash\": \"sha256-$nightly_hash\"|" $nightly_file
done

echo -e "\e[0;36mfetching nightly core\e[0m" > /dev/stderr
nightly_core_hash=$(fetch-sha256 "$uri/cores/core-nightly.tar.gz" "$nightly_artifacts/moonbit-core.tar.gz")
$sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$nightly_core_hash\"|" $nightly_file

if ! git diff --quiet -- "$nightly_file" || [[ "$old_nightly_version" != nightly-* ]]; then
  nightly_version="nightly-$(date -u +%F)"
  nightly_archive="$toolchains_dir/$nightly_version.json"
  if [ -e "$nightly_archive" ]; then
    echo "error: nightly changed more than once on $(date -u +%F)" > /dev/stderr
    exit 1
  fi
  $sedi "s|version\": \".*\"|version\": \"$nightly_version\"|" $nightly_file
  cp "$nightly_file" "$nightly_archive"
  echo "nightly_version=$nightly_version" >> "$GITHUB_OUTPUT"
else
  rm -rf "$nightly_artifacts"
fi

# ---------------------------------------------------------------------------
# latest channel (pinned)
#
# Fetch the upstream `latest` build, resolve its concrete version, pin it to a
# per-version file and let the workflow mirror it to a GitHub release.
# ---------------------------------------------------------------------------
run_version=""
old_version=$($sednr 's|^\s*"version\": \"(.*)\",$|\1|p' $latest_file)
for target in linux-x86_64 darwin-aarch64; do # Keep the linux-x86_64 first
  # phase 0
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
      moon_version=$(nix run .\#moon version | head -n1)

      # remove the date suffix after the whitespace
      if [[ "$run_version" == *" "* ]]; then
        run_version="${run_version%% *}"
      fi

      # append moon git short rev (short_rev) to run_version
      short_rev=$(echo "$moon_version" | sed -r 's/.*\((.*) .*\)/\1/')
      if [ -n "$short_rev" ]; then
        run_version="${run_version}+${short_rev}"
      fi
    fi

    if [ -z "${run_version}" ] || [ -z "${moon_version}" ]; then
      echo -e "error: failed get version from toolchain" > /dev/stderr
      exit 1
    fi

    echo -e "\e[0;36mcurrent version: \e[1;36m$run_version\e[0m" > /dev/stderr

    # skip if latest version not changed
    if [ "$run_version" == "$old_version" ]; then
      echo -e "\e[0;33mlatest version not changed ($run_version), skipping latest\e[0m" > /dev/stderr
      # revert the transient "updating" mutation so only nightly changes (if
      # any) remain in the working tree
      git checkout -- $latest_file
      break
    fi

    # update latest
    $sedi "s|version\": \".*\"|version\": \"$run_version\"|" $latest_file

    echo -e "\e[0;36mfetching core\e[0m" > /dev/stderr
    target_hash=$(fetch-sha256 "$uri/cores/core-latest.tar.gz" "moonbit-core.tar.gz")
    $sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$target_hash\"|" $latest_file

    # pin
    cp $latest_file "$toolchains_dir/$run_version.json"

    # output version to action (triggers the GitHub release of the new latest)
    echo "version=$run_version" >> "$GITHUB_OUTPUT"
  fi
done

# ---------------------------------------------------------------------------
# If nothing changed at all (neither latest nor nightly), tell the workflow to
# skip the commit step.
# ---------------------------------------------------------------------------
if git diff --quiet -- "$toolchains_dir"; then
  echo -e "\e[0;33mnothing changed (latest + nightly), skipping\e[0m" > /dev/stderr
  echo "skipped=true" >> "$GITHUB_OUTPUT"
fi

echo "done" > /dev/stderr
