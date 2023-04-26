{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-std.url = "github:chessai/nix-std";

    nixfmt = {
      url = "github:serokell/nixfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = {
        nixosModules = {
          kvmfr = import ./modules/kvmfr { std = inputs.nix-std.lib; };
        };
      };

      perSystem = { system, pkgs, self', ... }: {
        checks.kvmfr = import ./tests/kvmfr {
          inherit pkgs;
          module = self.nixosModules.kvmfr;
        };

        packages = {
          docs-options = pkgs.callPackage ./docs/module-options-doc.nix {
            modules = (self.nixosModules);
          };
          docs-book = pkgs.callPackage ./docs/docbook.nix {
            module-options-doc = self'.packages.docs-options;
          };
        };

        formatter = inputs.nixfmt.packages.${system}.default;
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            mdbook
            inputs.nixfmt.packages.${system}.default
          ];
        };
      };
    };
}
