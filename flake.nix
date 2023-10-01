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
          kvmfr = import ./modules/kvmfr { std = inputs.nix-std.lib; };
          libvirtd = import ./modules/libvirtd;
          virtualisation = import ./modules/virtualisation;
          vfio = import ./modules/vfio;
        };
      };

      perSystem = { system, pkgs, self', lib, ... }: {
        checks = {
          kvmfr = import ./tests/kvmfr {
            inherit pkgs;
            module = self.nixosModules.kvmfr;
          };
          libvirtd = import ./tests/libvirtd {
            inherit pkgs;
            imports = lib.attrValues self.nixosModules;
          };
          virtualisation = import ./tests/virtualisation {
            inherit pkgs;
            module = self.nixosModules.virtualisation;
          };
        };

        packages = {
          docs-options = pkgs.callPackage ./docs/module-options-doc.nix {
            modules = (self.nixosModules);
          };
          docs-book = pkgs.callPackage ./docs/docbook.nix {
            module-options-doc = self'.packages.docs-options;
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
