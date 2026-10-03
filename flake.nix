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
          version = "0.10.1";
          src = self;

          nativeBuildInputs = [ pkgs.nim pkgs.stdenv.cc pkgs.makeWrapper pkgs.python3 ]
            ++ pkgs.lib.optional (pkgs ? nimble) pkgs.nimble;

          dontConfigure = true;
          buildPhase = ''
            nim c -d:release --nimcache:"$TMPDIR/nimcache" --path:src --out:starintel_conformance src/starintel_conformance.nim
            nim c -d:release --nimcache:"$TMPDIR/nimcache-legacy" --path:src --out:starintel_legacy_conformance src/starintel_legacy_conformance.nim
          '';

          doCheck = true;
          checkPhase = ''
            runHook preCheck

            export HOME="$TMPDIR"
            export NIMBLE_DIR="$TMPDIR/nimble"
            mkdir -p "$HOME" "$NIMBLE_DIR"

            command -v nimble >/dev/null
            nimble dump >/dev/null
            python3 scripts/sync-starintel-schema.py --offline
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.pcre ]}"
            nim c -r --nimcache:"$TMPDIR/nimcache-tests" --path:src tests/test_canonical.nim
            nim c -r --nimcache:"$TMPDIR/nimcache-legacy-tests" --path:src tests/test_conformance.nim

            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall

            root="$out/share/nimble/starintel_doc-0.10.1"
            mkdir -p "$root"

            for path in src schemas schema scripts starintel_doc.nimble README.md LICENSE changelog.org; do
              if [ -e "$path" ]; then
                cp -R "$path" "$root/"
              fi
            done

            ln -s "starintel_doc-0.10.1" "$out/share/nimble/starintel_doc"
            mkdir -p "$out/bin"
            install -m755 starintel_conformance starintel_legacy_conformance "$out/bin/"
            wrapProgram "$out/bin/starintel_conformance" --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.pcre ]}"

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
