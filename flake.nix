{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    utils = { url = "github:numtide/flake-utils"; };
    nix-std = { url = "github:chessai/nix-std"; };
  };

  outputs = { self, nixpkgs, utils, nix-std, ... } @ inputs:
    let
      std = nix-std.lib;
    in
    {
      nixosModules = {
        libvirt = import ./modules/libvirtd;
        kvmfr = import ./modules/kvmfr.nix { inherit std; };
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
