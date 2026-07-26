{
  description = "StarIntel v0.9.0 document specification for Nim";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkPackage = pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "starintel-doc-nim";
          version = "0.9.0";
          src = self;

          nativeBuildInputs = [ pkgs.nim ]
            ++ pkgs.lib.optional (pkgs ? nimble) pkgs.nimble;

          dontConfigure = true;
          dontBuild = true;

          doCheck = true;
          checkPhase = ''
            runHook preCheck

            command -v nimble >/dev/null
            nimble dump >/dev/null

            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall

            root="$out/share/nimble/starintel_doc-0.9.0"
            mkdir -p "$root"

            for path in src starintel_doc.nimble README.md LICENSE changelog.org; do
              if [ -e "$path" ]; then
                cp -R "$path" "$root/"
              fi
            done

            ln -s "starintel_doc-0.9.0" "$out/share/nimble/starintel_doc"

            runHook postInstall
          '';

          passthru = {
            nimblePath = "share/nimble/starintel_doc";
            sourcePath = "share/nimble/starintel_doc/src";
          };

          meta = {
            description = "StarIntel v0.9.0 parser, validator, serializer, and conformance adapter for Nim";
            homepage = "https://github.com/lost-rob0t/starintel-doc.nim";
          };
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          package = mkPackage pkgs;
        in
        {
          default = package;
          starintel-doc-nim = package;
        });

      checks = forAllSystems (system: {
        default = self.packages.${system}.starintel-doc-nim;
      });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.nim ]
              ++ pkgs.lib.optional (pkgs ? nimble) pkgs.nimble
              ++ pkgs.lib.optional (pkgs ? nim_lk) pkgs.nim_lk;
          };
        });

      overlays.default = final: _prev: {
        starintel-doc-nim = mkPackage final;
      };
    };
}
