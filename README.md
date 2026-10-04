# StarIntel documents for Nim

StarLang is the only document specification authority. The default `starintel_doc` module exposes generated 0.10.1 Nim types.
The `starintel_conformance` command uses the exact wire API and generated schema
and manifest. Both are pinned in `schema/starintel-schema.lock.json`.
The complete immutable release is vendored under `src/starintel_doc/schemas/starintel-0.10.1/`.

The runtime validates concrete document types, schema references, formats and
manifest decimal bounds/scale with exact string arithmetic. The default conformance CLI uses the exact JSON wire API and preserves optional
omission, false/null values and opaque extensions. Generated native typed object
codecs are an additional surface with native storage limits. Canonical fields are flat lowerCamelCase;
nested `data`, `_id` and `schema_version` are rejected.

Validation-only consumers can import `starintel_doc/validation`. This is the
same validator exported by `starintel_doc/canonical`, without instantiating the
90 generated typed codecs. Use `roundtripWireDocument` for the full canonical
JSON number domain. The `canonical` module additionally exposes generated typed
object codecs within their native representation limits.

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

## Installed library gate

`python3 scripts/test-installed-package.py` performs a real Nimble install and
compiles/runs the complete canonical suite outside this checkout. Both library
modules and immutable generated assets are explicitly included even though this
package also ships executable adapters. `--no-rebuild` is only for separately
compiled adapter binaries; it does not skip installed-library compilation.

### Exact JSON wire numbers

For input/output at a JSON boundary, import `starintel_doc/validation` and use
`parseWireJson(text)`, `validateDocument(value)` / `roundtripWireDocument(value)`,
and `stringifyWireJson(value)`. These preserve numeric lexemes before any machine
float conversion, including opaque extension decimals and integers outside int64.
Integer and min/max checks compare exact decimal values, including scientific
notation; numeric tokens cannot impersonate schema string fields.

The generated typed Nim structs still use native primitive representations such
as int64. They are not an arbitrary-precision storage API. Use the maintained
validation/JSON wire surface when handling schema-valid values beyond those
representations; the generated authority and schema are unchanged.

Both canonical CLI entry points use the lossless parser and wire roundtrip API.
After compiling either CLI, run `python3 tests/test_numeric_cli.py PATH_TO_BINARY`;
optional repeatable `--corpus FILE.ndjson` arguments verify additional documents.

Wire numbers may be unquoted raw-number `JString` nodes. Use `isJsonNumber`,
`isJsonInteger` and `compareJsonNumbers` for exact numeric semantics; native
`getInt`/`getFloat` accessors are not arbitrary-precision conversions. Consumers
must use the wire API before a lossy parser, not after values have been rounded.

## Raw JSON object keys

Raw JSON parsers reject duplicate decoded object keys, including equal values
and escaped spellings, before a mapping can overwrite them. Each object has its
own key scope. Unicode normalization is not applied to distinct key strings.
The shared raw-text regression corpus is vendored in fixtures/raw-json-unique-keys.json;
it must match the StarLang specs/starintel/wire authority copy. Already-parsed
objects cannot recover duplicates discarded by an upstream decoder.
