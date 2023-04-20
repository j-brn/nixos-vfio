{ lib, pkgs, nixosOptionsDoc, modules }:
let
  optionsDocs = with lib;
    mapAttrs (name: module:
      (nixosOptionsDoc { options = evalModules { modules = [ module ]; }; }))
    modules;

  commands = with lib;
    concatStringsSep "\n" (mapAttrsToList (name: doc: ''
      cat ${doc.optionsCommonMark} \
       | sed -r 's/\[\/nix\/store\/.+\-source\/(.+\.nix)\]/[\1]/g' \
       | sed -r 's/file\:\/\/\/nix\/store\/.+\-source\/(.+\.nix)/https\:\/\/github\.com\/j-brn\/nixos\-vfio\/tree\/master\/\1/g' \
       >> $out/${name}.md
    '') optionsDocs);

in pkgs.runCommand "nixos-options-combined" { } ''
  mkdir $out
  ${commands}
''
