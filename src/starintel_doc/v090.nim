import std/[json, os, strutils, algorithm]

const
  SpecVersion* = "0.9.0"
  AdapterVersion* = 1


type ValidationResult* = object
  ok*: bool
  category*: string
  message*: string


proc success(): ValidationResult = ValidationResult(ok: true)

proc failure(category, message: string): ValidationResult =
  ValidationResult(ok: false, category: category, message: message)


proc schemaPath*(): string =
  let explicit = getEnv("STARINTEL_SCHEMA")
  if explicit.len > 0:
    return explicit
  let root = getEnv("STARINTEL_CONFORMANCE_ROOT")
  if root.len > 0:
    return root / "schemas" / "starintel-doc-v0.9.0.schema.json"
  result = getCurrentDir() / "schemas" / "starintel-doc-v0.9.0.schema.json"


proc loadSchema*(): JsonNode =
  let target = schemaPath()
  if not fileExists(target):
    raise newException(IOError, "StarIntel schema not found: " & target)
  result = parseFile(target)


proc jsonType(value: JsonNode): string =
  case value.kind
  of JNull: "null"
  of JBool: "boolean"
  of JInt: "integer"
  of JFloat: "number"
  of JString: "string"
  of JArray: "array"
  of JObject: "object"


proc isNumber(value: JsonNode): bool = value.kind in {JInt, JFloat}

proc asFloat(value: JsonNode): float =
  if value.kind == JInt: value.getInt.float else: value.getFloat

proc digits(value: string, first, last: int): bool =
  if first < 0 or last >= value.len or first > last:
    return false
  for index in first .. last:
    if value[index] notin {'0' .. '9'}:
      return false
  true

proc component(value: string, first, last: int): int =
  parseInt(value[first .. last])

proc validDateTime(value: string): bool =
  if value.len < 20:
    return false
  if value[4] != '-' or value[7] != '-' or value[10] != 'T' or
     value[13] != ':' or value[16] != ':':
    return false
  if not digits(value, 0, 3) or not digits(value, 5, 6) or
     not digits(value, 8, 9) or not digits(value, 11, 12) or
     not digits(value, 14, 15) or not digits(value, 17, 18):
    return false
  let month = component(value, 5, 6)
  let day = component(value, 8, 9)
  let hour = component(value, 11, 12)
  let minute = component(value, 14, 15)
  let second = component(value, 17, 18)
  if month notin 1 .. 12 or day notin 1 .. 31 or hour notin 0 .. 23 or
     minute notin 0 .. 59 or second notin 0 .. 60:
    return false

  var zone = 19
  if value[zone] == '.':
    inc zone
    let fractionStart = zone
    while zone < value.len and value[zone] in {'0' .. '9'}:
      inc zone
    if zone == fractionStart:
      return false
  if zone >= value.len:
    return false
  if value[zone] == 'Z':
    return zone == value.high
  if value[zone] notin {'+', '-'} or zone + 5 != value.high:
    return false
  if value[zone + 3] != ':' or not digits(value, zone + 1, zone + 2) or
     not digits(value, zone + 4, zone + 5):
    return false
  let offsetHour = component(value, zone + 1, zone + 2)
  let offsetMinute = component(value, zone + 4, zone + 5)
  offsetHour <= 23 and offsetMinute <= 59


proc matchesType(value: JsonNode, expected: string): bool =
  case expected
  of "null": value.kind == JNull
  of "boolean": value.kind == JBool
  of "integer": value.kind == JInt
  of "number": value.kind in {JInt, JFloat}
  of "string": value.kind == JString
  of "array": value.kind == JArray
  of "object": value.kind == JObject
  else: true


proc validateValue*(value, schema: JsonNode, path = "$" ): ValidationResult

proc validateAnyOf(value, schema: JsonNode, path: string): ValidationResult =
  for candidate in schema["anyOf"].items:
    let checked = validateValue(value, candidate, path)
    if checked.ok:
      return checked
  failure("wrong_type", path & ": value did not match any allowed schema")


proc validateObject(value, schema: JsonNode, path: string): ValidationResult =
  let properties = if schema.hasKey("properties"): schema["properties"] else: newJObject()
  if schema.hasKey("required"):
    for item in schema["required"].items:
      let key = item.getStr
      if not value.hasKey(key):
        return failure("missing_required_field", path & ": missing required field " & key)

  var additionalAllowed = true
  var additionalSchema: JsonNode = nil
  if schema.hasKey("additionalProperties"):
    let additional = schema["additionalProperties"]
    if additional.kind == JBool:
      additionalAllowed = additional.getBool
    elif additional.kind == JObject:
      additionalSchema = additional

  for key, item in value.pairs:
    if properties.hasKey(key):
      let checked = validateValue(item, properties[key], path & "." & key)
      if not checked.ok:
        return checked
    elif additionalSchema != nil:
      let checked = validateValue(item, additionalSchema, path & "." & key)
      if not checked.ok:
        return checked
    elif not additionalAllowed:
      return failure("undeclared_field", path & ": undeclared field " & key)
  success()


proc validateValue*(value, schema: JsonNode, path = "$" ): ValidationResult =
  if schema.kind != JObject or schema.len == 0:
    return success()
  if schema.hasKey("anyOf"):
    return validateAnyOf(value, schema, path)
  if schema.hasKey("const") and value != schema["const"]:
    return failure("invalid_constant", path & ": unexpected constant")
  if schema.hasKey("enum"):
    var found = false
    for item in schema["enum"].items:
      if item == value:
        found = true
        break
    if not found:
      return failure("invalid_enum", path & ": value is not in enum")
  if schema.hasKey("type"):
    let expected = schema["type"].getStr
    if not matchesType(value, expected):
      return failure("wrong_type", path & ": expected " & expected & ", got " & jsonType(value))

  if value.kind == JString:
    let text = value.getStr
    if schema.hasKey("format") and schema["format"].getStr == "date-time" and not validDateTime(text):
      return failure("invalid_datetime", path & ": invalid ISO-8601 date-time")
    if schema.hasKey("pattern"):
      let pattern = schema["pattern"].getStr
      if pattern == "^[^/\\\\\\x00]+$":
        if text.len == 0 or '/' in text or '\\' in text or '\0' in text:
          return failure("pattern_mismatch", path & ": string does not match pattern")
      else:
        return failure("adapter_failure", path & ": unsupported schema pattern " & pattern)

  if isNumber(value):
    if schema.hasKey("minimum") and asFloat(value) < asFloat(schema["minimum"]):
      return failure("below_minimum", path & ": number is below minimum")
    if schema.hasKey("maximum") and asFloat(value) > asFloat(schema["maximum"]):
      return failure("above_maximum", path & ": number is above maximum")

  if value.kind == JArray and schema.hasKey("items"):
    for index in 0 ..< value.len:
      let checked = validateValue(value[index], schema["items"], path & "[" & $index & "]")
      if not checked.ok:
        return checked

  if value.kind == JObject:
    let checked = validateObject(value, schema, path)
    if not checked.ok:
      return checked

  if schema.hasKey("allOf"):
    for branch in schema["allOf"].items:
      var applies = true
      if branch.hasKey("if"):
        applies = validateValue(value, branch["if"], path).ok
      if applies and branch.hasKey("then"):
        let checked = validateValue(value, branch["then"], path)
        if not checked.ok:
          return checked
  success()


proc objectTypes*(schema: JsonNode): seq[string] =
  if not schema.hasKey("allOf"):
    return
  for branch in schema["allOf"].items:
    if branch.hasKey("if") and branch["if"].hasKey("properties") and
       branch["if"]["properties"].hasKey("dtype") and
       branch["if"]["properties"]["dtype"].hasKey("const"):
      result.add(branch["if"]["properties"]["dtype"]["const"].getStr)
  result.sort()


proc validateDocument*(document, schema: JsonNode): ValidationResult =
  if document.kind != JObject:
    return failure("wrong_type", "$: expected object")
  if not document.hasKey("schema_version") or document["schema_version"].kind != JString or
     document["schema_version"].getStr != SpecVersion:
    return failure("unsupported_spec_version", "$.schema_version: unsupported version")
  if document.hasKey("dtype") and document["dtype"].kind == JString:
    let dtype = document["dtype"].getStr
    if dtype notin objectTypes(schema):
      let aliases = ["organization", "organisation", "investigation_target", "social_media_post",
                     "email_message", "financial_observation", "research_pass", "dataset_manifest",
                     "actor_manifest", "legal_case", "lobbying_filing", "campaign_finance"]
      if dtype in aliases:
        return failure("invalid_enum", "$.dtype: alias is not canonical")
      return failure("unknown_object_type", "$.dtype: unknown document type")
  result = validateValue(document, schema)
  if not result.ok and result.category == "invalid_constant":
    result.category = "unsupported_spec_version"


proc roundtrip*(document, schema: JsonNode): tuple[validation: ValidationResult, document: JsonNode] =
  let checked = validateDocument(document, schema)
  if not checked.ok:
    return (checked, newJNull())
  let encoded = $document
  let decoded = parseJson(encoded)
  let rechecked = validateDocument(decoded, schema)
  (rechecked, decoded)


proc schemaInventory*(schema: JsonNode): JsonNode =
  result = newJArray()
  if not schema.hasKey("allOf"):
    return
  var entries: seq[(string, JsonNode)]
  for branch in schema["allOf"].items:
    let dtype = branch["if"]["properties"]["dtype"]["const"].getStr
    let dataSchema = branch["then"]["properties"]["data"]
    entries.add((dtype, dataSchema))
  entries.sort(proc(a, b: (string, JsonNode)): int = cmp(a[0], b[0]))
  for entry in entries:
    let dtype = entry[0]
    let dataSchema = entry[1]
    var required: seq[string]
    if dataSchema.hasKey("required"):
      for item in dataSchema["required"].items:
        required.add(item.getStr)
    var fields = newJObject()
    if dataSchema.hasKey("properties"):
      var names: seq[string]
      for name, _ in dataSchema["properties"].pairs:
        names.add(name)
      names.sort()
      for name in names:
        let definition = dataSchema["properties"][name]
        var field = newJObject()
        field["required"] = %(name in required)
        if definition.hasKey("type"):
          field["type"] = definition["type"]
        if definition.hasKey("format"):
          field["format"] = definition["format"]
        if definition.hasKey("enum"):
          field["enum"] = definition["enum"]
        if definition.hasKey("anyOf"):
          var choices = newJArray()
          for candidate in definition["anyOf"].items:
            if candidate.hasKey("type"):
              choices.add(candidate["type"])
            elif candidate.hasKey("const"):
              choices.add(candidate["const"])
            else:
              choices.add(%"any")
          field["any_of"] = choices
        fields[name] = field
    result.add(%*{"object_type": dtype, "fields": fields})
