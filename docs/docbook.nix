{ pkgs, lib, moduleDoc, ... }:
let inherit (pkgs) stdenv mdbook;
in stdenv.mkDerivation {
  name = "nixos-vfio-docs";
  src = ./book;

  buildInputs = [ moduleDoc ];
  nativeBuildInputs = [ mdbook ];

  buildPhase = ''
    ln -s ${moduleDoc}/options.md ./src
    mdbook build
  '';

  installPhase = ''
    mv book $out
  '';
}
