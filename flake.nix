{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-std.url = "github:chessai/nix-std";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    devshell.url = "github:numtide/devshell";

    nixfmt = {
      url = "github:serokell/nixfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks.flakeModule
      ];
      systems = [ "x86_64-linux" ];
      perSystem = { system, ... }: {
        formatter = inputs.nixfmt.packages.${system}.default;

        devshells.default = {
          packages = [

          ];
        };
      };
    };
}
