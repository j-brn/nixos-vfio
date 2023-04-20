{ lib, pkgs, nixosOptionsDoc, modules }:
let
  optionsDocs = with lib;
    mapAttrs (name: module:
      (nixosOptionsDoc { options = evalModules { modules = [ module ]; }; }))
    modules;

  mvCommands = with lib;
    concatStringsSep "\n" (mapAttrsToList (name: doc: ''
      cat ${doc.optionsCommonMark} >> $out/${name}.md
    '') optionsDocs);

in pkgs.runCommand "nixos-options-combined" { } ''
  mkdir $out
  ${mvCommands}
''
