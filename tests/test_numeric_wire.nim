import std/[json, strutils]
import ../src/starintel_doc/validation
proc person(value: string): JsonNode = parseWireJson("""{"id":"fixture:numeric","dataset":"interop","dtype":"person","schemaVersion":"0.10.1","createdAt":""" & value & "}")
for number in ["0", "9007199254740993", "9223372036854775808", "1.00", "1e40", "1e99999999999999999999999999999", "-0e-99999999999999999999"]:
  doAssert validateDocument(person(number)).ok, number
  doAssert stringifyWireJson(person(number)).contains(number), number
for number in ["-1", "-9223372036854775808", "1.01", "1e-99999999999999999999999999999", "\"9223372036854775808\""]:
  doAssert not validateDocument(person(number)).ok, number
let original = """{"id":"fixture:numeric","dataset":"interop","dtype":"person","schemaVersion":"0.10.1","extensions":{"precise":0.12345678901234567890123456789,"null":null,"false":false,"integer":9223372036854775809}}"""
doAssert stringifyWireJson(parseWireJson(original)) == original
for (a,b,order) in [("1e300000000000000000000", "9e299999999999999999999", 1), ("1e-300000000000000000000", "9e-299999999999999999999", -1), ("0.123456789012345678901", "0.123456789012345678902", -1), ("-5", "-4", -1), ("100.000", "1e2", 0)]:
  doAssert cmp(compareJsonNumbers(parseWireJson(a),parseWireJson(b)), 0) == order
# Raw numeric tokens may never impersonate string fields.
let bad = parseWireJson("""{"id":9223372036854775808,"dataset":"interop","dtype":"person","schemaVersion":"0.10.1"}""")
doAssert not validateDocument(bad).ok
# Exact constraint checks do not round an invalid near-boundary integer.
let schema = loadSchema()
schema["$defs"]["UnixTime"]["maximum"] = parseWireJson("9007199254740992")
doAssert validateDocument(person("9007199254740992"), schema).ok
doAssert not validateDocument(person("9007199254740993"), schema).ok
echo "Lossless numeric wire and exact validation passed"
for text in ["01", ".1", "1.", "1e", "1e+", "+1", "[01]", "{\"x\":1e}", "[1,]", "{\"x\":1,}", "/*x*/1", "NaN", "Infinity", "\"\\ud800\"", "\"\\udc00\"", "\"\xC0\x80\""]:
  var rejected = false
  try: discard parseWireJson(text)
  except ValueError: rejected = true
  doAssert rejected, "accepted non-JSON: " & text
doAssert stringifyWireJson(parseWireJson("-0")) == "-0"
doAssert stringifyWireJson(parseWireJson("0.00000000000000000000001")) == "0.00000000000000000000001"
echo "Strict wire syntax passed"
# Even programmatic values parsed through permissive std/json must not pass.
for token in ["1e", "1e+", "1."]:
  let value = parseJson("""{"id":"fixture:numeric","dataset":"interop","dtype":"person","schemaVersion":"0.10.1","extensions":{"n":""" & token & "}}", rawFloats=true)
  doAssert not validateDocument(value).ok
for nested in ["[1e]", "[{\"bad\":[1e+]}]"]:
  let value = parseJson("""{"id":"fixture:numeric","dataset":"interop","dtype":"person","schemaVersion":"0.10.1","extensions":{"nested":""" & nested & "}}", rawFloats=true)
  doAssert not validateDocument(value).ok
for invalidUtf8 in ["\xED\xA0\x80", "\xF4\x90\x80\x80", "\xF5\x80\x80\x80", "\xE0\x80\x80", "\xF0\x80\x80\x80"]:
  var rejected = false
  try: discard parseWireJson("\"" & invalidUtf8 & "\"")
  except ValueError: rejected = true
  doAssert rejected, "invalid UTF-8 scalar accepted"
