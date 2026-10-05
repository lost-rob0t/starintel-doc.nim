## StarLang-generated 0.10.1 schema/manifest are the only wire authority.
import ./operation_semantics
import ./json_wire
export json_wire
import std/[json, strutils, re, times]

const
  SpecVersion* = "0.10.1"
  AdapterVersion* = 1
  SchemaText = staticRead("schemas/starintel-0.10.1/generated/schema.json")
  ManifestText = staticRead("schemas/starintel-0.10.1/generated/portable-manifest.json")

type ValidationResult* = object
  ok*: bool
  category*: string
  message*: string

proc failure(category, message: string): ValidationResult =
  ValidationResult(ok: false, category: category, message: message)
proc success(): ValidationResult = ValidationResult(ok: true)
proc loadSchema*(): JsonNode = parseJson(SchemaText)
proc loadManifest*(): JsonNode = parseJson(ManifestText)
proc definitionName(name: string): string =
  for word in name.split('/')[^1].split('-'):
    result.add(word[0].toUpperAscii & word[1..^1])
proc objectTypes*(schema: JsonNode): seq[string] =
  for item in loadManifest()["types"]:
    if item["kind"].getStr == "document" and item.getOrDefault("persistence").getStr("persistent") == "persistent": result.add(item["name"].getStr.split('/')[^1])

proc decimalParts(value: string): tuple[negative: bool, whole, fraction: string] =
  var text = value
  result.negative = text.startsWith("-")
  if text[0] in {'-', '+'}: text = text[1..^1]
  let parts = text.split('.')
  result.whole = parts[0].strip(leading = true, trailing = false, chars = {'0'})
  if result.whole.len == 0: result.whole = "0"
  result.fraction = if parts.len == 2: parts[1] else: ""
  if result.whole == "0" and result.fraction.strip(chars = {'0'}).len == 0:
    result.negative = false

proc compareDecimal(a, b: string): int =
  let x = decimalParts(a)
  let y = decimalParts(b)
  if x.negative != y.negative: return if x.negative: -1 else: 1
  var magnitude = cmp(x.whole.len, y.whole.len)
  if magnitude == 0: magnitude = cmp(x.whole, y.whole)
  if magnitude == 0:
    let width = max(x.fraction.len, y.fraction.len)
    magnitude = cmp(x.fraction.alignLeft(width, '0'), y.fraction.alignLeft(width, '0'))
  result = if x.negative: -magnitude else: magnitude

proc validDate(value: string): bool =
  if not value.match(re"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"): return false
  try:
    let parsed = parse(value, "yyyy-MM-dd", utc())
    result = parsed.format("yyyy-MM-dd") == value
  except ValueError: result = false

proc validDateTime(value: string): bool =
  if not value.match(re"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$"):
    return false
  if not validDate(value[0..9]): return false
  result = parseInt(value[11..12]) <= 23 and parseInt(value[14..15]) <= 59 and
    parseInt(value[17..18]) <= 60
  if result and value[^1] != 'Z':
    result = parseInt(value[^5..^4]) <= 23 and parseInt(value[^2..^1]) <= 59

proc validateValue(value, node, root, manifest: JsonNode, path: string): ValidationResult =
  if (value.kind == JString and not isJsonString(value) or value.kind == JFloat) and not isJsonNumber(value):
    return failure("invalid_number", path & ": invalid JSON number")
  if node.kind != JObject: return success()
  if node.hasKey("$ref"):
    let name = node["$ref"].getStr.split('/')[^1]
    if not root["$defs"].hasKey(name): return failure("adapter_failure", path & ": unresolved reference")
    let checked = validateValue(value, root["$defs"][name], root, manifest, path)
    if not checked.ok: return checked
    for constraint in manifest["types"]:
      if constraint["kind"].getStr == "scalar" and constraint["base"].getStr == "decimal" and
          definitionName(constraint["name"].getStr) == name:
        let text = value.getStr
        if constraint.hasKey("minimum") and compareDecimal(text, $constraint["minimum"]) < 0:
          return failure("below_minimum", path & ": below decimal minimum")
        if constraint.hasKey("maximum") and compareDecimal(text, $constraint["maximum"]) > 0:
          return failure("above_maximum", path & ": above decimal maximum")
        if constraint.hasKey("scale") and decimalParts(text).fraction.len > constraint["scale"].getInt:
          return failure("invalid_scale", path & ": exceeds decimal scale")
    return success()
  if node.hasKey("anyOf"):
    for branch in node["anyOf"]:
      let checked = validateValue(value, branch, root, manifest, path)
      if checked.ok: return checked
    return failure("wrong_type", path & ": no allowed variant matches")
  if node.hasKey("type"):
    let expected = node["type"].getStr
    let matched = case expected
      of "object": value.kind == JObject
      of "array": value.kind == JArray
      of "string": isJsonString(value)
      of "integer": isJsonInteger(value)
      of "number": isJsonNumber(value)
      of "boolean": value.kind == JBool
      of "null": value.kind == JNull
      else: false
    if not matched: return failure("wrong_type", path & ": expected " & expected)
  if node.hasKey("enum"):
    var found = false
    for choice in node["enum"]:
      if choice == value: found = true
    if not found: return failure("invalid_enum", path & ": value is not in enum")
  if isJsonString(value):
    let text = value.getStr
    if node.hasKey("pattern") and not text.contains(re(node["pattern"].getStr)):
      return failure("pattern_mismatch", path & ": value does not match pattern")
    if node.hasKey("format"):
      let valid = case node["format"].getStr
        of "date": validDate(text)
        of "date-time": validDateTime(text)
        of "uri": text.match(re"^[A-Za-z][A-Za-z0-9+.-]*:[^\s]*$")
        else: false
      if not valid: return failure("invalid_format", path & ": invalid " & node["format"].getStr)
  if isJsonNumber(value):
    if node.hasKey("minimum") and compareJsonNumbers(value, node["minimum"]) < 0:
      return failure("below_minimum", path & ": below minimum")
    if node.hasKey("maximum") and compareJsonNumbers(value, node["maximum"]) > 0:
      return failure("above_maximum", path & ": above maximum")
  if value.kind == JObject:
    if node.hasKey("required"):
      for key in node["required"]:
        if not value.hasKey(key.getStr): return failure("missing_required_field", path & ": missing " & key.getStr)
    for key, item in value:
      var child = newJObject()
      if node.hasKey("properties") and node["properties"].hasKey(key): child = node["properties"][key]
      elif node.hasKey("additionalProperties"):
        let additional = node["additionalProperties"]
        if additional.kind == JBool and not additional.getBool:
          return failure("undeclared_field", path & ": undeclared " & key)
        if additional.kind == JObject: child = additional
      let checked = validateValue(item, child, root, manifest, path & "." & key)
      if not checked.ok: return checked
  if value.kind == JArray:
    let itemSchema = if node.hasKey("items"): node["items"] else: newJObject()
    for index in 0 ..< value.len:
      let checked = validateValue(value[index], itemSchema, root, manifest, path & "[" & $index & "]")
      if not checked.ok: return checked
  success()

proc validateDocument*(document: JsonNode, schema: JsonNode = loadSchema()): ValidationResult =
  if document.kind != JObject: return failure("wrong_type", "$: expected object")
  if not document.hasKey("schemaVersion") or document["schemaVersion"].kind != JString or
      document["schemaVersion"].getStr != SpecVersion:
    return failure("unsupported_spec_version", "$.schemaVersion: expected " & SpecVersion)
  if not document.hasKey("dtype") or document["dtype"].kind != JString or
      document["dtype"].getStr notin objectTypes(schema):
    return failure("unknown_object_type", "$.dtype: unknown document type")
  let structural = validateValue(document, schema["$defs"][definitionName(document["dtype"].getStr)], schema, loadManifest(), "$")
  if not structural.ok: return structural
  try:
    validateOperationSemantics(document)
    validateWorkflowSemantics(document)
  except ValueError as error:
    return failure("operation_semantics", error.msg)
  success()

proc roundtripWireDocument*(document: JsonNode, schema: JsonNode = loadSchema()): tuple[validation: ValidationResult, document: JsonNode] =
  ## Maintained unbounded JSON wire path. Generated native typed models are an
  ## additive surface and may have narrower primitive storage representations.
  let checked = validateDocument(document, schema)
  if not checked.ok: return (checked, newJNull())
  let decoded = parseWireJson(stringifyWireJson(document))
  (validateDocument(decoded, schema), decoded)
