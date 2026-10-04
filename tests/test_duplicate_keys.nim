import std/[json, strutils]
import ../src/starintel_doc/validation

# Keep the fixture text raw until it enters the SDK-owned boundary. std/json
# reads only the fixture container; it must never pre-parse an entry's wire.
const FixtureText = staticRead("fixtures/raw-json-unique-keys.json")
let fixture = parseJson(FixtureText)
var count = 0
for entry in fixture["cases"]:
  let raw = entry["wire"].getStr
  let valid = entry["valid"].getBool
  var accepted = true
  var message = ""
  try:
    let value = parseWireJson(raw)
    doAssert validateDocument(value).ok, entry["name"].getStr
    doAssert stringifyWireJson(parseWireJson(stringifyWireJson(value))) == stringifyWireJson(value)
  except ValueError as error:
    accepted = false
    message = error.msg
  doAssert accepted == valid, entry["name"].getStr & ": " & message
  if not valid: doAssert "duplicate JSON key" in message
  inc count

echo count, " shared raw JSON key cases passed"
