{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, utils, ... } @ inputs:
    {
      nixosModules.libvirtdHooks = import ./modules/libvirtd-hooks.nix;
    }
    // utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
          ];
        };
      }
    );
}
