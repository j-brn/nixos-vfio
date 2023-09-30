{ pkgs, lib, module-options-doc, ... }:
let inherit (pkgs) stdenv mdbook;
in stdenv.mkDerivation {
  name = "nixos-vfio-docs";
  src = ./book;

  buildInputs = [ module-options-doc ];
  nativeBuildInputs = [ mdbook ];

  buildPhase = ''
    ln -s ${module-options-doc} ./src/options
    mdbook build
  '';

  installPhase = ''
    mv book $out
  '';
}
