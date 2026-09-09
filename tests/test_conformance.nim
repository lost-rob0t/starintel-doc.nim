import std/json
import ../src/starintel_doc/v090

proc document(): JsonNode =
  parseJson("""{
    "_id":"starintel:person:nim-test",
    "dataset":"test",
    "dtype":"person",
    "schema_version":"0.9.0",
    "version":1,
    "date_added":"2026-01-02T03:04:05Z",
    "date_updated":"2026-01-02T03:04:05+00:00",
    "sources":[],
    "evidence":[],
    "data":{"fname":"Ada","lname":"Lovelace","bio":"Unicode λ 漢字 🧠"},
    "extensions":{"example.test":{"integer":9007199254740991,"number":1.25,"null":null,"empty_array":[],"empty_object":{}}}
  }""")

proc operationDocument(): JsonNode =
  parseJson("""{
    "_id":"starintel:operation:nim-091",
    "dataset":"conformance-v0.9.1",
    "dtype":"operation",
    "schema_version":"0.9.0",
    "version":1,
    "date_added":"2026-09-09T01:00:00Z",
    "date_updated":"2026-09-09T01:00:00Z",
    "sources":[],
    "evidence":[],
    "data":{
      "mission":"Exercise operation support in the Nim binding.",
      "status":"planned",
      "phases":[{
        "phase_id":"plan",
        "objective":"Prove native operation round-trip.",
        "state":"planned",
        "depends_on":[],
        "dataset_binding_ids":[],
        "required_capability_ids":[]
      }]
    }
  }""")

let schema = loadSchema()

block validRoundtrip:
  let value = document()
  let checked = roundtrip(value, schema)
  doAssert checked.validation.ok
  doAssert checked.document == value

block operationRoundtrip091:
  let value = operationDocument()
  let checked = roundtrip(value, schema)
  doAssert checked.validation.ok
  doAssert checked.document == value

block missingRequired:
  let value = document()
  value.delete("_id")
  let checked = validateDocument(value, schema)
  doAssert not checked.ok
  doAssert checked.category == "missing_required_field"

block unsupportedVersion:
  let value = document()
  value["schema_version"] = %"0.8.0"
  let checked = validateDocument(value, schema)
  doAssert not checked.ok
  doAssert checked.category == "unsupported_spec_version"
