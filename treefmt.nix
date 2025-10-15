{ ... }:

{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    shellcheck.enable = true;
  };
  settings.global.excludes = [
    "LICENSE"
    "*.json"
    "**/.envrc"
  ];
}
