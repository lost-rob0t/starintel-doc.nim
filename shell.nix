{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    git
    pre-commit
    nim
    lcov
    nodejs
  ];
}
