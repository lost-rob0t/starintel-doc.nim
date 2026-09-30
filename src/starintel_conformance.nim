import std/json
import starintel_doc/v0101
import starintel_doc/migration

proc emit(value: JsonNode) =
  stdout.write($value & "\n")

proc errorResponse(category, message: string): JsonNode =
  %*{"ok": false, "error": category, "message": message}

proc main(): int =
  try:
    let request = parseJson(stdin.readAll())
    if request.kind != JObject:
      emit(errorResponse("adapter_failure", "request must be a JSON object"))
      return 2
    let command = if request.hasKey("command"): request["command"].getStr else: ""
    if command == "version":
      emit(%*{"ok": true, "language": "nim", "specVersion": SpecVersion, "adapterVersion": AdapterVersion})
      return 0
    if command == "capabilities":
      emit(%*{
        "ok": true,
        "language": "nim",
        "adapterVersion": AdapterVersion,
        "specVersions": ["0.9.0", SpecVersion],
        "emittedSpecVersion": SpecVersion,
        "commands": ["validate", "normalize", "roundtrip", "migrate", "migrateBatch", "version", "capabilities", "schemaInventory"],
        "objectTypes": objectTypes(),
        "preservesUnknownExtensions": true,
        "preservesMissingOptionalFields": true
      })
      return 0

    let requestedVersion = if request.hasKey("specVersion"): request["specVersion"].getStr
      elif request.hasKey("spec_version"): request["spec_version"].getStr
      else: SpecVersion
    if requestedVersion notin ["0.9.0", SpecVersion]:
      emit(errorResponse("unsupportedSchemaVersion", requestedVersion))
      return 3

    if command in ["schemaInventory", "schema-inventory"]:
      emit(%*{"ok": true, "specVersion": SpecVersion, "inventory": schemaInventory()})
      return 0

    if command == "migrateBatch":
      let migrated = migrateBatch(request["documents"])
      migrated["ok"] = %true
      migrated["specVersion"] = %SpecVersion
      emit(migrated)
      return 0

    if not request.hasKey("document"):
      emit(errorResponse("wrong_type", "document is required"))
      return 1

    let document = request["document"]
    if command == "migrate":
      var documents = newJArray()
      for migrated in migrateDocument(document):
        documents.add(migrated)
      emit(%*{"ok": true, "specVersion": SpecVersion, "documents": documents})
      return 0
    if command == "validate":
      let checked = validateDocument(document)
      if checked.ok:
        emit(%*{"ok": true, "specVersion": SpecVersion, "warnings": []})
        return 0
      emit(errorResponse(checked.category, checked.message))
      return if checked.category == "unsupportedSchemaVersion": 3 else: 1

    if command in ["normalize", "roundtrip"]:
      let checked = roundtrip(document)
      if checked.validation.ok:
        emit(%*{"ok": true, "specVersion": SpecVersion, "document": checked.document, "warnings": []})
        return 0
      emit(errorResponse(checked.validation.category, checked.validation.message))
      return if checked.validation.category == "unsupportedSchemaVersion": 3 else: 1

    emit(errorResponse("adapter_failure", "unsupported command: " & command))
    return 2
  except MigrationError as error:
    emit(errorResponse(error.reasonCode, error.msg))
    return 1
  except CatchableError as error:
    stderr.writeLine("nim adapter failure: " & error.msg)
    emit(errorResponse("adapter_failure", error.msg))
    return 2

when isMainModule:
  quit(main())
