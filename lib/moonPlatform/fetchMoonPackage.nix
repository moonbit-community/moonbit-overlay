# Trivial fetcher for moon package zip
{ fetchurl }:
let
  fetchMoonPackage =
    {
      name,
      version,
      moonCacheUri ? "https://moonbitlang-mooncakes.s3.us-west-2.amazonaws.com",
      sha256,
    }:
    fetchurl {
      url = "${moonCacheUri}/user/${name}/${version}.zip";
      inherit sha256;
    };
in
fetchMoonPackage
