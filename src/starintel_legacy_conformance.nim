import std/[json, strutils]
import starintel_doc/v090

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
    let schema = loadSchema()

    if command == "version":
      emit(%*{"ok": true, "language": "nim", "spec_version": SpecVersion, "adapter_version": AdapterVersion})
      return 0
    if command == "capabilities":
      emit(%*{
        "ok": true,
        "language": "nim",
        "adapter_version": AdapterVersion,
        "spec_versions": [SpecVersion],
        "commands": ["validate", "normalize", "roundtrip", "version", "capabilities", "schema-inventory"],
        "object_types": objectTypes(schema),
        "preserves_unknown_extensions": true,
        "preserves_missing_optional_fields": true
      })
      return 0

    if request.hasKey("spec_version") and request["spec_version"].getStr != SpecVersion:
      emit(errorResponse("unsupported_spec_version", request["spec_version"].getStr))
      return 3

    if command == "schema-inventory":
      emit(%*{"ok": true, "spec_version": SpecVersion, "inventory": schemaInventory(schema)})
      return 0

    if not request.hasKey("document"):
      emit(errorResponse("wrong_type", "document is required"))
      return 1

    let document = request["document"]
    if command == "validate":
      let checked = validateDocument(document, schema)
      if checked.ok:
        emit(%*{"ok": true, "spec_version": SpecVersion, "warnings": []})
        return 0
      emit(errorResponse(checked.category, checked.message))
      return if checked.category == "unsupported_spec_version": 3 else: 1

    if command in ["normalize", "roundtrip"]:
      let checked = roundtrip(document, schema)
      if checked.validation.ok:
        emit(%*{"ok": true, "spec_version": SpecVersion, "document": checked.document, "warnings": []})
        return 0
      emit(errorResponse(checked.validation.category, checked.validation.message))
      return if checked.validation.category == "unsupported_spec_version": 3 else: 1

    emit(errorResponse("adapter_failure", "unsupported command: " & command))
    return 2
  except CatchableError as error:
    stderr.writeLine("nim adapter failure: " & error.msg)
    emit(errorResponse("adapter_failure", error.msg))
    return 2

when isMainModule:
  quit(main())
