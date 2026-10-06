import std/[json, strutils]
import ../src/starintel_doc/validation

doAssert objectTypes(loadSchema()).len == 90
let person = %*{"id":"person:test", "dtype":"person", "dataset":"test", "schemaVersion":"0.10.1"}
doAssert validateDocument(person).ok
person["confidence"] = %"1.0001"
doAssert not validateDocument(person).ok
let cycle = %*{"id":"operation:test", "dtype":"operation", "dataset":"test", "schemaVersion":"0.10.1", "mission":"Verify evidence", "status":"planned", "phases":[{"phaseId":"collect", "objective":"Collect evidence", "state":"planned", "dependsOn":["collect"]}]}
doAssert not validateDocument(cycle).ok

# Generated defaults wrap their actual constraint in allOf. Exercise every
# current occurrence through the validation-only and exact wire APIs.
proc definitionName(dtype: string): string =
  for word in dtype.split('-'):
    result.add(word[0].toUpperAscii & word[1..^1])

proc requiredSample(node, schema: JsonNode): JsonNode =
  if node.hasKey("$ref"):
    return requiredSample(schema["$defs"][node["$ref"].getStr.split('/')[^1]], schema)
  if node.hasKey("enum"): return node["enum"][0]
  if node.hasKey("allOf"): return requiredSample(node["allOf"][0], schema)
  case node["type"].getStr
  of "object":
    result = newJObject()
    if node.hasKey("required"):
      for key in node["required"]:
        result[key.getStr] = requiredSample(node["properties"][key.getStr], schema)
  of "array": result = newJArray()
  of "integer", "number":
    result = if node.hasKey("minimum"): node["minimum"] else: %0
  of "boolean": result = %false
  else:
    if node.hasKey("format") and node["format"].getStr == "uri":
      return %"https://example.test/"
    result = if node.hasKey("pattern"): %"0" else: %"fixture"

block defaultFieldConformance:
  let schema = loadSchema()
  var checkedFields = 0
  for dtype in objectTypes(schema):
    let definition = schema["$defs"][definitionName(dtype)]
    for field, constraint in definition["properties"]:
      if not constraint.hasKey("allOf"): continue
      inc checkedFields
      let value = requiredSample(definition, schema)
      value["dtype"] = %dtype
      value["schemaVersion"] = %SpecVersion
      doAssert validateDocument(value).ok, dtype & ": required-only baseline"
      doAssert roundtripWireDocument(value).document == value, dtype & ": optional omission"
      value[field] = constraint["default"]
      doAssert validateDocument(value).ok, dtype & "." & field & ": declared default"
      doAssert roundtripWireDocument(value).document == value, dtype & "." & field & ": preserve default"
      let expected = constraint["allOf"][0]["type"].getStr
      if expected == "boolean":
        value[field] = %(not constraint["default"].getBool)
        doAssert roundtripWireDocument(value).validation.ok, dtype & "." & field & ": opposite boolean"
      let wrongPrimitive = if expected == "boolean": %"false" else: %7
      for invalid in [wrongPrimitive, newJNull(), newJObject(), newJArray()]:
        value[field] = invalid
        let checked = validateDocument(value)
        doAssert not checked.ok, dtype & "." & field & ": wrong type accepted"
        doAssert checked.category == "wrong_type"
        doAssert checked.message == "$." & field & ": expected " & expected
        doAssert not roundtripWireDocument(value).validation.ok
  doAssert checkedFields == 33

# Check conjunction rather than first-branch/anyOf behavior, and ensure
# successful allOf validation does not skip sibling constraints.
block conjunctionAndSiblingConstraints:
  let schema = loadSchema()
  schema["$defs"]["Person"]["properties"]["age"] = %*{
    "allOf": [{"type": "integer"}, {"minimum": 5}], "maximum": 10}
  let value = %*{"id":"person:allof", "dtype":"person", "dataset":"test", "schemaVersion":"0.10.1", "age":7}
  doAssert validateDocument(value, schema).ok
  value["age"] = %3
  let below = validateDocument(value, schema)
  doAssert not below.ok and below.category == "below_minimum"
  doAssert below.message == "$.age: below minimum"
  value["age"] = %12
  let above = validateDocument(value, schema)
  doAssert not above.ok and above.category == "above_maximum"
  doAssert above.message == "$.age: above maximum"
echo "Validation-only API: inventory, decimals, operations and allOf constraints passed"
