#!/usr/bin/env bash

toolchains_dir="./versions/toolchains"
latest_file="$toolchains_dir/latest.json"
nightly_file="$toolchains_dir/nightly.json"
uri="https://cli.moonbitlang.com"

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

# ---------------------------------------------------------------------------
# nightly channel (rolling)
#
# Unlike `latest`, nightly is not pinned to a per-version file nor mirrored to a
# GitHub release: utils.nix points the nightly URLs straight at upstream, so we
# only need to keep the hashes in nightly.json fresh. This runs unconditionally
# (and before the `latest` block) so nightly is refreshed every day even when
# `latest` has not changed.
# ---------------------------------------------------------------------------
echo -e "\e[0;36mfetching nightly toolchains\e[0m" > /dev/stderr
for target in linux-x86_64 darwin-aarch64; do
  nightly_uri="$uri/binaries/nightly/moonbit-$target.tar.gz"
  nightly_hash=$(fetch-sha256 "$nightly_uri" "moonbit-$target.tar.gz")
  $sedi "s|$target-toolchainsHash\": \"sha256-.*\"|$target-toolchainsHash\": \"sha256-$nightly_hash\"|" $nightly_file
done

echo -e "\e[0;36mfetching nightly core\e[0m" > /dev/stderr
nightly_core_hash=$(fetch-sha256 "$uri/cores/core-nightly.tar.gz" "moonbit-core.tar.gz")
$sedi "s|coreHash\": \"sha256-.*\"|coreHash\": \"sha256-$nightly_core_hash\"|" $nightly_file

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
