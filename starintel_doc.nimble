# Package

version = "0.9.1"
author = "nsaspy"
description = "StarIntel 0.9.1 parser, validator, serializer, and operation-compatible conformance adapter"
license = "AGPL-3.0-only"
srcDir = "src"
bin = @["starintel_conformance"]

requires "nim >= 2.0.0"
requires "ulid"
requires "regex"

task test, "Run StarIntel tests":
  exec "nim c -r --path:src tests/test_conformance.nim"
