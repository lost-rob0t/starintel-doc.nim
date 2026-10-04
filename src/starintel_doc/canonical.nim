## Full canonical API, including all generated typed codecs.
## Validation-only consumers may import starintel_doc/validation to avoid
## instantiating codecs they never use. Both paths share identical validation.
import ./validation
export validation
import std/[json, jsonutils, strutils, macros]
import "schemas/starintel-0.10.1/generated/starintel_types" as generated
const ManifestText = staticRead("schemas/starintel-0.10.1/generated/portable-manifest.json")
proc definitionName(name: string): string =
  for word in name.split('/')[^1].split('-'):
    result.add(word[0].toUpperAscii & word[1..^1])

macro generatedRoundtrip(value: JsonNode): JsonNode =
  var source = "case " & value.repr & "[\"dtype\"].getStr\n"
  for item in parseJson(ManifestText)["types"]:
    if item["kind"].getStr != "document" or item.getOrDefault("persistence").getStr("persistent") != "persistent": continue
    let dtype = item["name"].getStr.split('/')[^1]
    source.add("of \"" & dtype & "\":\n  toJson(jsonTo(" & value.repr & ", generated." & definitionName(dtype) &
      ", Joptions(allowMissingKeys: true)))\n")
  source.add("else: newJObject()")
  result = parseStmt(source)

proc preserveOmission(input, encoded: JsonNode): JsonNode =
  case input.kind
  of JObject:
    result = newJObject()
    for key, value in input:
      result[key] = preserveOmission(value, encoded[key])
  of JArray:
    result = newJArray()
    for index in 0 ..< input.len:
      result.add(preserveOmission(input[index], encoded[index]))
  else: result = encoded

proc roundtrip*(document: JsonNode, schema: JsonNode = loadSchema()): tuple[validation: ValidationResult, document: JsonNode] =
  let checked = validateDocument(document, schema)
  if not checked.ok: return (checked, newJNull())
  let encoded = generatedRoundtrip(document)
  # Typed embedded records also contain optional slots. Preserve absence at
  # every nesting level while retaining actual generated-binding values.
  let projected = preserveOmission(document, encoded)
  let decoded = parseJson($projected)
  (validateDocument(decoded, schema), decoded)
