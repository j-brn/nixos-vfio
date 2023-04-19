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
        nixosModules.kvmfr =
          import ./modules/kvmfr { std = inputs.nix-std.lib; };
      };

      perSystem = { system, pkgs, ... }: {
        checks.kvmfr = import ./tests/kvmfr {
          inherit pkgs;
          module = self.nixosModules.kvmfr;
        };

        packages.docs = pkgs.callPackage ./docs/options-doc.nix {
          modules = { kvmfr = ./modules/kvmfr/options.nix; };
        };
        formatter = inputs.nixfmt.packages.${system}.default;
        devShells.default = pkgs.mkShellNoCC { };
      };
    };
}