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
          kvmfr = import ./modules/kvmfr { std = inputs.nix-std.lib; }; };
          vfio = import ./modules/vfio;
      };

      perSystem = { system, pkgs, ... }: {
        checks.kvmfr = import ./tests/kvmfr {
          inherit pkgs;
          module = self.nixosModules.kvmfr;
        };

        packages.module-options-doc =
          pkgs.callPackage ./docs/module-options-doc.nix {
            modules = {
              kvmfr = ./modules/kvmfr/options.nix;
              vfio = ./modules/vfio/options.nix;
            };
          };

        packages.docbook = pkgs.callPackage ./docs/docbook.nix {
          module-options-doc = self.packages.${system}.module-options-doc;
        };

        formatter = inputs.nixfmt.packages.${system}.default;
        devShells.default =
          pkgs.mkShellNoCC { buildInputs = with pkgs; [ mdbook ]; };
      };
    };
}
