{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    utils = { url = "github:numtide/flake-utils"; };
    std = { url = "github:chessai/nix-std"; };
  };

  outputs = { self, nixpkgs, utils, std, ... } @ inputs:
    {
      nixosModules = {
        libvirtdHooks = import ./modules/libvirtd-hooks.nix;
        kvmfr = import ./modules/kvmfr.nix;
      };
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
