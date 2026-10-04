import std/[json, os]
import ../src/starintel_doc/canonical
var count = 0
for fixture in parseFile(paramStr(1)):
  let validation = validateDocument(fixture["document"])
  doAssert validation.ok == fixture["valid"].getBool, fixture["name"].getStr & ": " & validation.message
  inc count
echo count, " research fixtures passed"
