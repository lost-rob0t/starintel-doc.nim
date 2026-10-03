import std/[json, strutils]
import ../src/starintel_doc/canonical

let schema = loadSchema()

proc definitionName(dtype: string): string =
  for word in dtype.split('-'): result.add(word[0].toUpperAscii & word[1..^1])

proc sample(node: JsonNode): JsonNode =
  if node.hasKey("$ref"): return sample(schema["$defs"][node["$ref"].getStr.split('/')[^1]])
  if node.hasKey("enum"): return node["enum"][0]
  if node.hasKey("anyOf"): return sample(node["anyOf"][0])
  case node["type"].getStr
  of "object":
    result = newJObject()
    if node.hasKey("required"):
      for key in node["required"]: result[key.getStr] = sample(node["properties"][key.getStr])
  of "array": result = newJArray()
  of "integer", "number": result = if node.hasKey("minimum"): node["minimum"] else: %0
  of "boolean": result = %false
  else:
    if node.hasKey("format"):
      case node["format"].getStr
      of "date-time": return %"2026-10-03T12:00:00Z"
      of "date": return %"2026-10-03"
      of "uri": return %"https://example.test/"
      else: discard
    if node.hasKey("pattern"):
      let pattern = node["pattern"].getStr
      if "@" in pattern: return %"fixture@example.test"
      if "0-9()." in pattern: return %"+123456789"
      return %"0"
    result = %"fixture"

proc document(dtype: string): JsonNode =
  result = sample(schema["$defs"][definitionName(dtype)])
  result["id"] = %("fixture:" & dtype)
  result["dataset"] = %"conformance"
  result["dtype"] = %dtype
  result["schemaVersion"] = %SpecVersion

doAssert objectTypes(schema).len == 60
for dtype in objectTypes(schema):
  let value = document(dtype)
  let encoded = roundtrip(value)
  doAssert encoded.validation.ok, dtype & ": " & encoded.validation.message
  doAssert encoded.document == value, dtype & ": generated binding roundtrip changed wire data"

for bad in [
  ("person", "id", %"invalid space"), ("person", "createdAt", %(-1)),
  ("geo-point", "latitude", %"90.00000001"), ("person", "confidence", %"0.12345"),
  ("person", "confidence", %"1.1"), ("person", "confidence", %0.5),
  ("person", "dob", %"2026-02-30"), ("url", "url", %"invalid URL with spaces"),
  ("person", "dtype", %"made-up"), ("person", "schemaVersion", %"0.10.2"),
  ("person", "data", newJObject()), ("person", "_id", %"legacy"),
  ("person", "sources", %*[{"id": "source"}]), ("wireless-network", "security", %"wpa4")]:
  let value = document(bad[0])
  value[bad[1]] = bad[2]
  doAssert not validateDocument(value).ok, bad[0] & "." & bad[1]

let station = document("wireless-station")
station.delete("mac")
doAssert not validateDocument(station).ok
doAssert not validateDocument(%*{"_id": "old", "dtype": "person", "schema_version": "0.10.1", "data": {}}).ok
let opaque = document("person")
opaque["deleted"] = %false
opaque["extensions"] = %*{"example.vendor": {"opaque_key": nil, "flag": false, "items": []}}
doAssert roundtrip(opaque).document == opaque
echo "StarLang 0.10.1: all 60 generated Nim document bindings and strict runtime checks passed"
