# Package

version = "0.10.1"
author = "nsaspy"
description = "StarLang-generated StarIntel 0.10.1 runtime with explicit historical compatibility"
license = "AGPL-3.0-only"
srcDir = "src"
installDirs = @["starintel_doc"]
installFiles = @["starintel_doc.nim"]
bin = @["starintel_conformance", "starintel_legacy_conformance"]

requires "nim >= 2.0.0"
requires "ulid"
requires "regex"

task test, "Run StarIntel tests":
  exec "nim c -r --path:src tests/test_conformance.nim"
