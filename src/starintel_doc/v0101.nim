import std/[algorithm, json, re, strutils, tables]

const
  SpecVersion* = "0.10.1"
  AdapterVersion* = 2
  SchemaText = staticRead("../../schema/starintel-0.10.1.schema.json")
  ManifestText = staticRead("../../schema/starintel-0.10.1.manifest.json")

let
  CanonicalSchema* = parseJson(SchemaText)
  CanonicalManifest* = parseJson(ManifestText)

type ValidationResult* = object
  ok*: bool
  category*: string
  message*: string

proc success(): ValidationResult = ValidationResult(ok: true)

proc failure(category, message: string): ValidationResult =
  ValidationResult(ok: false, category: category, message: message)

proc definitionName(dtype: string): string =
  for part in dtype.split('-'):
    if part.len > 0:
      result.add(part[0].toUpperAscii)
      if part.len > 1:
        result.add(part[1 .. ^1])

proc documentDefinitions*(): Table[string, string] =
  for contract in CanonicalManifest["types"].items:
    if contract["kind"].getStr != "document":
      continue
    let dtype = contract["name"].getStr.split('/')[^1]
    result[dtype] = definitionName(dtype)

proc objectTypes*(): seq[string] =
  for dtype in documentDefinitions().keys:
    result.add(dtype)
  result.sort()

proc jsonType(value: JsonNode): string =
  case value.kind
  of JNull: "null"
  of JBool: "boolean"
  of JInt: "integer"
  of JFloat: "number"
  of JString: "string"
  of JArray: "array"
  of JObject: "object"

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

proc validateValue(value, rule: JsonNode, path = "$" ): ValidationResult

proc validateValue(value, rule: JsonNode, path = "$" ): ValidationResult =
  if rule.kind != JObject:
    return success()
  if rule.hasKey("$ref"):
    let reference = rule["$ref"].getStr
    const prefix = "#/$defs/"
    if not reference.startsWith(prefix):
      return failure("canonicalValidationFailed", path & ": unsupported reference")
    let name = reference[prefix.len .. ^1]
    if not CanonicalSchema["$defs"].hasKey(name):
      return failure("canonicalValidationFailed", path & ": missing reference " & name)
    return validateValue(value, CanonicalSchema["$defs"][name], path)
  if rule.hasKey("anyOf"):
    for candidate in rule["anyOf"].items:
      let checked = validateValue(value, candidate, path)
      if checked.ok:
        return checked
    return failure("wrongType", path & ": value did not match any allowed schema")
  if rule.hasKey("const") and value != rule["const"]:
    return failure("invalidConstant", path & ": unexpected constant")
  if rule.hasKey("enum"):
    var found = false
    for candidate in rule["enum"].items:
      if candidate == value:
        found = true
        break
    if not found:
      return failure("invalidEnum", path & ": value is not in enum")
  if rule.hasKey("type"):
    let expected = rule["type"].getStr
    if not matchesType(value, expected):
      return failure("wrongType", path & ": expected " & expected & ", got " & jsonType(value))
  if value.kind == JString and rule.hasKey("pattern"):
    if not value.getStr.match(re(rule["pattern"].getStr)):
      return failure("patternMismatch", path & ": string does not match pattern")
  if value.kind in {JInt, JFloat}:
    let number = if value.kind == JInt: value.getInt.float else: value.getFloat
    if rule.hasKey("minimum"):
      let minimum = if rule["minimum"].kind == JInt: rule["minimum"].getInt.float else: rule["minimum"].getFloat
      if number < minimum:
        return failure("belowMinimum", path & ": number is below minimum")
    if rule.hasKey("maximum"):
      let maximum = if rule["maximum"].kind == JInt: rule["maximum"].getInt.float else: rule["maximum"].getFloat
      if number > maximum:
        return failure("aboveMaximum", path & ": number is above maximum")
  if value.kind == JArray and rule.hasKey("items"):
    for index in 0 ..< value.len:
      let checked = validateValue(value[index], rule["items"], path & "[" & $index & "]")
      if not checked.ok:
        return checked
  if value.kind == JObject:
    let properties = if rule.hasKey("properties"): rule["properties"] else: newJObject()
    if rule.hasKey("required"):
      for item in rule["required"].items:
        if not value.hasKey(item.getStr):
          return failure("missingRequiredField", path & ": missing required field " & item.getStr)
    let additionalAllowed = not rule.hasKey("additionalProperties") or
      rule["additionalProperties"].kind != JBool or rule["additionalProperties"].getBool
    for key, item in value.pairs:
      if properties.hasKey(key):
        let checked = validateValue(item, properties[key], path & "." & key)
        if not checked.ok:
          return checked
      elif not additionalAllowed:
        return failure("undeclaredField", path & ": undeclared field " & key)
  success()

proc validateDocument*(document: JsonNode): ValidationResult =
  if document.kind != JObject:
    return failure("wrongType", "$: expected object")
  if not document.hasKey("schemaVersion") or document["schemaVersion"].kind != JString or
      document["schemaVersion"].getStr != SpecVersion:
    return failure("unsupportedSchemaVersion", "$.schemaVersion: unsupported version")
  if not document.hasKey("dtype") or document["dtype"].kind != JString:
    return failure("missingRequiredField", "$: missing required field dtype")
  let dtype = document["dtype"].getStr
  let definitions = documentDefinitions()
  if not definitions.hasKey(dtype) or not CanonicalSchema["$defs"].hasKey(definitions[dtype]):
    return failure("unknownObjectType", "$.dtype: unknown document type")
  validateValue(document, CanonicalSchema["$defs"][definitions[dtype]])

proc roundtrip*(document: JsonNode): tuple[validation: ValidationResult, document: JsonNode] =
  let checked = validateDocument(document)
  if not checked.ok:
    return (checked, newJNull())
  let decoded = parseJson($document)
  (validateDocument(decoded), decoded)

proc schemaInventory*(): JsonNode =
  result = newJArray()
  let definitions = documentDefinitions()
  for dtype in objectTypes():
    result.add(%*{"dtype": dtype, "definition": definitions[dtype]})
