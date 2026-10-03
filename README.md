# StarIntel documents for Nim

StarLang is the only document specification authority. The default
`starintel_doc` module and `starintel_conformance` command consume the generated
0.10.1 schema, manifest and Nim types pinned in `schema/starintel-schema.lock.json`.
The complete immutable release is vendored under `schemas/starintel-0.10.1/`.

The runtime validates concrete document types, schema references, formats and
manifest decimal bounds/scale with exact string arithmetic. Round trips pass
through the generated Nim objects and preserve optional omission, false/null
values and opaque extensions. Canonical fields are flat lowerCamelCase;
nested `data`, `_id` and `schema_version` are rejected.

Historical wire APIs remain explicitly available through `starintel_doc/v090`,
`starintel_doc/legacy` and the separate `starintel_legacy_conformance` command.
They are not relabeled 0.10.1. The legacy source lock is archived separately.
Migration policy and fixtures belong to StarLang; no corpus rewrite is performed.

```sh
python3 scripts/sync-starintel-schema.py --commit FULL_IMMUTABLE_STARLANG_SHA
python3 scripts/sync-starintel-schema.py       # exact upstream check in CI
python3 scripts/sync-starintel-schema.py --offline
nim c -r --path:src tests/test_canonical.nim
nim c -r --path:src tests/test_conformance.nim
nix flake check -L
```

The native runtime needs PCRE 8 (`libpcre3` on Debian/Ubuntu); the Nix package
provides it. Nim 2.2.4 is the validated compiler baseline.
