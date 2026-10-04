import std/json
import ../src/starintel_doc/validation

doAssert objectTypes(loadSchema()).len == 90
let person = %*{"id":"person:test", "dtype":"person", "dataset":"test", "schemaVersion":"0.10.1"}
doAssert validateDocument(person).ok
person["confidence"] = %"1.0001"
doAssert not validateDocument(person).ok
let cycle = %*{"id":"operation:test", "dtype":"operation", "dataset":"test", "schemaVersion":"0.10.1", "mission":"Verify evidence", "status":"planned", "phases":[{"phaseId":"collect", "objective":"Collect evidence", "state":"planned", "dependsOn":["collect"]}]}
doAssert not validateDocument(cycle).ok
echo "Installed validation-only API: 90-type inventory, decimal and operation rejection passed"
