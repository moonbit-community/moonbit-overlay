{ lib
, fetchFromGitHub
, ocamlPackages
}:

ocamlPackages.buildDunePackage {
  pname = "moonbit-lang";
  version = "unstable-2024-12-18";

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
