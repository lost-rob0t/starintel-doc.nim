{ pkgs ? import <nixpkgs> { } }: pkgs.mkShell {
  buildInputs = with pkgs; [ nim-unwrapped nimble-unwrapped ];
}
