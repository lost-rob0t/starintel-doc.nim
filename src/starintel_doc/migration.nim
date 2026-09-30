import std/[algorithm, json, strutils, tables]
import ./v0101
import ./private/sha256

const
  CompatibilityText = staticRead("../../schema/starintel-0.10.1.compatibility.json")
  FixtureText = staticRead("../../schema/starintel-0.10.1.compatibility-fixtures.json")

let
  Compatibility* = parseJson(CompatibilityText)
  CompatibilityFixtures* = parseJson(FixtureText)

type MigrationError* = object of CatchableError
  reasonCode*: string

proc migrationFailure(reasonCode, message: string): ref MigrationError =
  result = newException(MigrationError, message)
  result.reasonCode = reasonCode

proc camel(name: string): string =
  var upper = false
  for character in name:
    if character == '_':
      upper = true
    elif upper:
      result.add(character.toUpperAscii)
      upper = false
    else:
      result.add(character)

proc contains(values: JsonNode, target: string): bool =
  for value in values.items:
    if value.getStr == target:
      return true

proc normalizedObject(value, aliases, opaqueFields: JsonNode): JsonNode =
  result = newJObject()
  for source, item in value.pairs:
    let target = if aliases.hasKey(source): aliases[source].getStr else: camel(source)
    if result.hasKey(target):
      raise migrationFailure("ambiguousFieldCollision", "multiple fields normalize to " & target)
    if opaqueFields.contains(target):
      result[target] = item.copy
    elif item.kind == JObject:
      result[target] = normalizedObject(item, aliases, opaqueFields)
    elif item.kind == JArray:
      var entries = newJArray()
      for entry in item.items:
        entries.add(if entry.kind == JObject: normalizedObject(entry, aliases, opaqueFields) else: entry.copy)
      result[target] = entries
    else:
      result[target] = item.copy

proc mergeLegacyData(document: JsonNode) =
  if not document.hasKey("data"):
    return
  let data = document["data"]
  document.delete("data")
  if data.kind != JObject:
    raise migrationFailure("migrationFailed", "legacy data must be an object")
  for key, value in data.pairs:
    if document.hasKey(key):
      raise migrationFailure("ambiguousFieldCollision", "legacy data collides at " & key)
    document[key] = value.copy

proc classifyMedia(document: JsonNode) =
  let policy = Compatibility["mediaClassification"]
  if document["dtype"].getStr != policy["legacyDtype"].getStr:
    return
  var mediaType = ""
  for field in policy["contentTypePrecedence"].items:
    let name = field.getStr
    if document.hasKey(name) and document[name].kind == JString and document[name].getStr.len > 0:
      mediaType = document[name].getStr.toLowerAscii
      break
  document["dtype"] = policy["fallbackDtype"].copy
  for rule in policy["rules"].items:
    if mediaType.startsWith(rule["prefix"].getStr):
      document["dtype"] = rule["dtype"].copy
      break

proc convertGeo(document: JsonNode) =
  let policy = Compatibility["geo"]
  if document["dtype"].getStr != policy["legacyDtype"].getStr:
    return
  for source, targetNode in policy["fieldAliases"].pairs:
    let normalizedSource = camel(source)
    let target = targetNode.getStr
    if not document.hasKey(normalizedSource):
      continue
    if document.hasKey(target):
      raise migrationFailure("ambiguousFieldCollision", "geo field collides at " & target)
    document[target] = document[normalizedSource].copy
    document.delete(normalizedSource)
  document["dtype"] = policy["canonicalDtype"].copy
  for key, value in policy["defaults"].pairs:
    if not document.hasKey(key):
      document[key] = value.copy
  try:
    let longitude = parseFloat(document["longitude"].getStr)
    let latitude = parseFloat(document["latitude"].getStr)
    if longitude < -180.0 or longitude > 180.0 or latitude < -90.0 or latitude > 90.0:
      raise migrationFailure("canonicalValidationFailed", "geo coordinate is outside its valid range")
  except KeyError, ValueError:
    raise migrationFailure("migrationFailed", "legacy geo requires decimal lat and long")

proc reference(dtype, identifier: string): JsonNode =
  %*{"schema": "org.starintel/core@1/" & dtype, "id": identifier}

proc digestId(prefix: string, parts: openArray[string]): string =
  var input = prefix
  for part in parts:
    input.add('\0')
    input.add(part)
  sha256Hex(input)

proc extractPersonIdentifiers(document: JsonNode): seq[JsonNode] =
  if document["dtype"].getStr != "person" or not document.hasKey("externalIds") or
      document["externalIds"].kind != JObject:
    return
  var schemes: seq[string]
  for scheme, _ in document["externalIds"].pairs:
    schemes.add(scheme)
  schemes.sort()
  var references = newJArray()
  for scheme in schemes:
    let rawValue = document["externalIds"][scheme]
    if rawValue.kind notin {JString, JInt}:
      continue
    let value = if rawValue.kind == JString: rawValue.getStr else: $rawValue.getInt
    let normalizedValue = value.strip.toLowerAscii
    let identifier = "starintel:person-identifier:" & digestId(
      "personIdentifier", [document["id"].getStr, scheme, normalizedValue])
    references.add(reference("person-identifier", identifier))
    result.add(%*{
      "id": identifier,
      "dataset": document["dataset"].getStr,
      "dtype": "person-identifier",
      "schemaVersion": SpecVersion,
      "person": reference("person", document["id"].getStr),
      "scheme": scheme,
      "value": value,
      "normalizedValue": normalizedValue
    })
  if references.len > 0:
    document["identifiers"] = references

proc extractTranscript(document: JsonNode): seq[JsonNode] =
  var text = ""
  for field in ["transcript", "transcriptText"]:
    if document.hasKey(field) and document[field].kind == JString and document[field].getStr.len > 0:
      text = document[field].getStr
      document.delete(field)
      break
  if text.len == 0:
    return
  let language = if document.hasKey("language"): document["language"].getStr else: ""
  let identifier = "starintel:transcript:" & digestId(
    "transcript", [document["id"].getStr, language])
  let transcriptReference = reference("transcript", identifier)
  if document["dtype"].getStr == "audio":
    document["transcripts"] = %*[transcriptReference]
  else:
    document["transcript"] = transcriptReference
  var transcript = %*{
    "id": identifier,
    "dataset": document["dataset"].getStr,
    "dtype": "transcript",
    "schemaVersion": SpecVersion,
    "sourceMedia": reference(document["dtype"].getStr, document["id"].getStr),
    "text": text
  }
  if language.len > 0:
    transcript["language"] = %language
  result.add(transcript)

proc preserveUnknown(document: JsonNode) =
  let definitions = documentDefinitions()
  let dtype = document["dtype"].getStr
  if not definitions.hasKey(dtype) or not CanonicalSchema["$defs"].hasKey(definitions[dtype]):
    raise migrationFailure("canonicalValidationFailed", "unknown dtype " & dtype)
  let properties = CanonicalSchema["$defs"][definitions[dtype]]["properties"]
  var unknown = newJObject()
  var names: seq[string]
  for key, _ in document.pairs:
    names.add(key)
  for key in names:
    if not properties.hasKey(key):
      unknown[key] = document[key].copy
      document.delete(key)
  if unknown.len == 0:
    return
  if not document.hasKey("extensions"):
    document["extensions"] = newJObject()
  if document["extensions"].kind != JObject or document["extensions"].hasKey("legacy"):
    raise migrationFailure("ambiguousFieldCollision", "extensions.legacy collides")
  document["extensions"]["legacy"] = unknown

proc migrateDocument*(value: JsonNode): seq[JsonNode] =
  if value.kind != JObject:
    raise migrationFailure("decodeFailed", "document must be an object")
  let legacy = Compatibility["legacyInput"]
  let document = normalizedObject(value, legacy["envelopeAliases"], legacy["opaqueMapFields"])
  if not document.hasKey("schemaVersion") or
      not Compatibility["acceptedSchemaVersions"].contains(document["schemaVersion"].getStr):
    raise migrationFailure("unsupportedSchemaVersion", "unsupported schema version")
  mergeLegacyData(document)
  let dtype = document["dtype"].getStr
  if Compatibility["dtypeAliases"].hasKey(dtype):
    document["dtype"] = Compatibility["dtypeAliases"][dtype].copy
  classifyMedia(document)
  convertGeo(document)
  document["schemaVersion"] = %SpecVersion
  result.add(document)
  result.add(extractPersonIdentifiers(document))
  result.add(extractTranscript(document))
  for migrated in result:
    preserveUnknown(migrated)
    let checked = validateDocument(migrated)
    if not checked.ok:
      raise migrationFailure("canonicalValidationFailed", checked.message)

proc migrateBatch*(values: JsonNode): JsonNode =
  var documents = newJArray()
  var quarantine = newJArray()
  for value in values.items:
    try:
      for document in migrateDocument(value):
        documents.add(document)
    except MigrationError as error:
      quarantine.add(%*{"reasonCode": error.reasonCode})
    except CatchableError:
      quarantine.add(%*{"reasonCode": "migrationFailed"})
  %*{"documents": documents, "quarantine": quarantine}
