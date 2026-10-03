import std/[json, strutils]
import starintel_doc/canonical

proc main(): int =
  try:
    let request = parseJson(stdin.readAll())
    let command = request["command"].getStr
    if request.hasKey("spec_version") and request["spec_version"].getStr != SpecVersion:
      stdout.writeLine($(%*{"ok": false, "error": "unsupported_spec_version"}))
      return 3
    if command == "version":
      stdout.writeLine($(%*{"ok": true, "language": "nim", "spec_version": SpecVersion}))
    elif command == "capabilities":
      stdout.writeLine($(%*{"ok": true, "spec_versions": [SpecVersion], "object_types": objectTypes(loadSchema()), "authority": loadManifest()["library"]}))
    elif command in ["validate", "roundtrip"]:
      let document = request["document"]
      let checked = validateDocument(document)
      if not checked.ok:
        stdout.writeLine($(%*{"ok": false, "error": checked.category, "message": checked.message}))
        return 1
      if command == "roundtrip":
        let encoded = roundtrip(document)
        if not encoded.validation.ok: raise newException(ValueError, encoded.validation.message)
        stdout.writeLine($(%*{"ok": true, "document": encoded.document}))
      else: stdout.writeLine($(%*{"ok": true}))
    else: raise newException(ValueError, "unsupported command")
    return 0
  except CatchableError as error:
    stdout.writeLine($(%*{"ok": false, "error": "adapter_failure", "message": error.msg}))
    return 2

when isMainModule: quit(main())
