{ lib
, fetchFromGitHub
, ocamlPackages
, ocaml
}:

ocamlPackages.buildDunePackage {
  pname = "moonbit-lang";
  version = "v0.1.20241202+8756d160d";

  minimalOCamlVersion = "4.14.2";
  doCheck = lib.versionAtLeast ocaml.version "4.05";

  src = fetchFromGitHub {
    owner = "moonbitlang";
    repo = "moonbit-compiler";
    rev = "cd13d25e7cbc9663ab6239ec2ba038bf7af49994";
    hash = "sha256-YhDwp68v4FJk8blKdliZBcjO4E8rFEM/RYhdcQlXrvI=";
  };

  meta = {
    description = "";
    homepage = "https://github.com/moonbitlang/moonbit-compiler";
    mainProgram = "moonbit-compiler";
    platforms = lib.platforms.all;
  };
}
