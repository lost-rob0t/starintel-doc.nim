# StarIntel Nim v0.9

The Nim runtime preserves the current object constructors while `dump()` emits the canonical StarIntel v0.9 envelope.

Subtype object fields are nested beneath `data`; timestamps are ISO-8601 strings; record versions are integers; string source values become structured source records; and every document receives a declared `schema_org` JSON-LD block.

```nim
var organization = newOrg("Example Org", "company")
organization.dataset = "example"
let wire = organization.dump

doAssert wire["schema_version"].getStr == "0.9.0"
doAssert wire["data"]["name"].getStr == "Example Org"
doAssert wire["schema_org"]["@type"].getStr == "Organization"
```

`load()` accepts the canonical nested wire representation and restores the legacy-compatible subtype object fields.
