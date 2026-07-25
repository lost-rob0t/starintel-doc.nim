# Package

version     = "0.9.0"
author      = "nsaspy"
description = "Canonical Nim runtime for StarIntel document schema v0.9.0"
license     = "GPL-3.0-or-later"
srcDir      = "src"

# Deps

requires "nim >= 2.0.0"
requires "ulid"
requires "regex"

task test, "Run canonical v0.9 tests":
  exec "nim c -r --path:src tests/test_v09.nim"
