# Package

version = "0.10.1"
author = "nsaspy"
description = "StarIntel 0.10.1 Nim binding generated from the Star-Lang authority"
license = "AGPL-3.0-only"
srcDir = "src"
bin = @["starintel_conformance"]

requires "nim >= 2.0.0"
requires "ulid"
requires "regex"

task test, "Run StarIntel tests":
  exec "nim c -r --path:src tests/test_conformance.nim"
  exec "nim c -r --path:src tests/test_v0101_migration.nim"
