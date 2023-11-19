{ stdenv, lib, pkgs, nixosOptionsDoc, ...}:

with lib;

name: module:

let
  options = (evalModules { modules = [ { config._module.check = false; } module ]; }).options;
  filteredOptions = (filterAttrs (key: _: key != "_module") options);
  docs = (nixosOptionsDoc { options = filteredOptions; warningsAreErrors = false; });
in pkgs.runCommand "options.md" { } ''
  mkdir $out
  cat ${docs.optionsCommonMark} \
    | sed -r 's/\[\/nix\/store\/.+\-source\/(.+\.nix)\]/[\1]/g' \
    | sed -r 's/\[\/nix\/store\/.+\-source\/(.+)\]/[\1\/default\.nix]/g' \
    | sed -r 's/\[flake\\.nix\\#nixosModules\\.(\w+)\/default\.nix\]/\[modules\/\1\/default\.nix\]/g' \
    | sed -r 's/file\:\/\/\/nix\/store\/.+\-source\/(.+\.nix)/https\:\/\/github\.com\/j-brn\/nixos\-vfio\/tree\/master\/\1/g' \
    | sed -r 's/file\:\/\/\/nix\/store\/.+\-source\/(.+)\)/https\:\/\/github\.com\/j-brn\/nixos\-vfio\/tree\/master\/\1\/default\.nix\)/g' \
    > $out/options.md
''
