{
  description = "Handle starintel documents";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}; in
      rec {
        packages = flake-utils.lib.flattenTree
          {
            starintel-doc-nim = pkgs.nimPackages.buildNimPackage {
              name = "starintel-doc-nim";
              src = ./.;
            };
          };
        defaultPackage = packages.template-nix-nim;
        apps.starintel-doc-nim = flake-utils.lib.mkApp { drv = packages.starintel-doc-nim; };
        defaultApp = apps.starintel-doc-nim;
        devShell = pkgs.callPackage ./shell.nix { };
      }
    );
}
