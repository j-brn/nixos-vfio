{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-std.url = "github:chessai/nix-std";
  };

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = {
        nixosModules = {
          vfio = {
            imports = [
              (import ./modules/kvmfr { std = inputs.nix-std.lib; })
              ./modules/libvirtd
              ./modules/vfio
              ./modules/virtualisation
            ];
          };

          default = self.nixosModules.vfio;
        };
      };

      perSystem = { system, pkgs, self', lib, ... }: let
        mkModuleDoc = (pkgs.callPackage (import ./lib/mkModuleDoc.nix) {});
      in {
        checks = {
          kvmfr = import ./tests/kvmfr {
            inherit pkgs;
            imports = [ self.nixosModules.vfio ];
          };
          libvirtd = import ./tests/libvirtd {
            inherit pkgs;
            imports = [ self.nixosModules.vfio ];
          };
          virtualisation = import ./tests/virtualisation {
            inherit pkgs;
            imports = [ self.nixosModules.vfio ];
          };
        };

        packages = rec {
          options-doc = mkModuleDoc "vfio" self.nixosModules.vfio;
          docbook = pkgs.callPackage ./docs/docbook.nix {
            moduleDoc = options-doc;
          };
        };

        formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt;
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            mdbook
            nixfmt
          ];
        };
      };
    };
}
