{ lib, pkgs, nixosOptionsDoc, modules }:
let
  optionsDocs = with lib;
    mapAttrs (name: module:
      (nixosOptionsDoc {
        options = evalModules {
          modules = [ module ];
        };
      })) modules;

  mvCommands = with lib;
    concatStringsSep "\n" (mapAttrsToList (name: doc: ''
      cat ${doc.optionsAsciiDoc} >> $out/${name}.adoc
    '') optionsDocs);

in pkgs.runCommand "nixos-options-combined" { } ''
  mkdir $out
  ${mvCommands}
''