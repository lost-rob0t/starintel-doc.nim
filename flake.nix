{
  description = "A template for packaging nim projects";
  inputs = {
    flake-nimble =  {
      flake = true;
      url = "https://github.com/nix-community/flake-nimble/archive/a48df7c801b1da371492f5689dfbd5f6a128a6c2.tar.gz";
    };
    nixpkgs = {
      flake = true;
      url = "https://github.com/NixOS/nixpkgs/archive/a7ecde854aee5c4c7cd6177f54a99d2c1ff28a31.tar.gz";
    };
  };

  outputs = { self, nimble, nixpkgs }:
    let inherit (nixpkgs) lib;
    in {
      starintel-doc.nim = nimPackages.buildNimPackage rec {
              pname = "starintel-doc.nim";
              version = "0.1.0";
              src = fetchFromGit {
                repo = "https://github.com/lost-rob0t/starintel-doc.nim";
                rev = version;
                hash = "sha256-uShf/q2wxqDqpSyqdmomecZ0TRYXKkvfGDKFtPLwmVk=";
              };
            };
    };
}
