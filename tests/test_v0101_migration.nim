import std/json
import ../src/starintel_doc/v0101
import ../src/starintel_doc/migration
import ../src/starintel_doc/generated/types
import ../src/starintel_doc/private/sha256

block sha256KnownVector:
  doAssert sha256Hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

block generatedAuthorityTypesCompile:
  var value: GeoPoint
  discard value
  doAssert "file" in objectTypes()
  doAssert "picture" in objectTypes()
  doAssert "video" in objectTypes()
  doAssert "audio" in objectTypes()
  doAssert "transcript" in objectTypes()
  doAssert "person-identifier" in objectTypes()
  doAssert "geo-point" in objectTypes()
  doAssert "location" in objectTypes()

block sharedCompatibilityFixtures:
  for fixture in CompatibilityFixtures["cases"].items:
    let actual = migrateBatch(%*[fixture["input"]])
    doAssert actual == fixture["expected"], fixture["name"].getStr

block migrationIsIdempotent:
  let fixture = CompatibilityFixtures["cases"][0]
  let first = migrateBatch(%*[fixture["input"]])
  let second = migrateBatch(first["documents"])
  doAssert first == second

block canonicalValidationRejectsSnakeCase:
  let value = %*{
    "id": "person-invalid",
    "dataset": "fixture",
    "dtype": "person",
    "schemaVersion": SpecVersion,
    "first_name": "Ada"
  }
  doAssert not validateDocument(value).ok

block badDocumentDoesNotStopBatch:
  let fixtures = CompatibilityFixtures["cases"]
  let result = migrateBatch(%*[fixtures[^1]["input"], fixtures[0]["input"]])
  doAssert result["quarantine"] == %*[{"reasonCode": "ambiguousFieldCollision"}]
  doAssert result["documents"][0]["id"].getStr == "person-current"
