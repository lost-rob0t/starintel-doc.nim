import ../../src/starintel_doc
import times
import json



proc testPerson() =
  let time = now().toTime.toUnix
  var doc = Person(dataset: "Tests", dtype: "person",
                         date_added: time, date_updated: time, id: "test")
  doc.fname = "Joe"
  doc.mname = "l"
  doc.lname = "Smith"
  doc.race = "white"
  doc.makeUUID
  doAssert doc.dataset == "Tests"
  doAssert doc.dtype == "person"
  doAssert doc.date_added == time
  doAssert doc.date_updated == time
  doAssert doc.id != "test"
  doAssert doc.fname == "Joe"
  doAssert doc.mname == "l"
  doAssert doc.lname == "Smith"
  doAssert doc.race == "white"
proc testOrg() =
  var doc = newOrg(name="Star Intel", etype="Software")
  assert doc.name == "Star Intel"
  assert doc.etype == "Software"
  assert doc.dtype == "org"
  doAssert doc.id != "test"


when isMainModule:
  echo "Testing: Person"
  testPerson()
  echo "Testing: Org"
  testOrg()
