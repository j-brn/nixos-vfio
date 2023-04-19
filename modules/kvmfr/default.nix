{ std }:
{ lib, ... }:

with lib;

{
  imports = [ ./options.nix (import ./implementation.nix { inherit std; }) ];
  meta.maintainers = with maintainers; [ j-brn ];
}
