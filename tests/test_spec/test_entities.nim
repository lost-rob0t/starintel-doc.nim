import ../../src/starintel_doc
import times
import json



proc testBookerPerson() =
  let time = now().toTime.toUnix
  var doc = BookerPerson(dataset: "Tests", dtype: "person",
                         date_added: time, date_updated: time, id: "test")
  doc.fname = "Joe"
  doc.mname = "l"
  doc.lname = "shmoe"

  doc.makeUUID
  doAssert doc.dataset == "Tests"
  doAssert doc.dtype == "person"
  doAssert doc.date_added == time
  doAssert doc.date_updated == time
  doAssert doc.id != "test"
  doAssert doc.fname == "Joe"
  doAssert doc.mname == "l"
  doAssert doc.lname == "shmoe"

proc testBookerOrg() =
  var doc = newOrg(name="Star Intel", etype="Software")
  assert doc.name == "Star Intel"
  assert doc.etype == "Software"
  assert doc.dtype == "org"
  doAssert doc.id != "test"


when isMainModule:
  echo "Testing: BookerPerson"
  testBookerPerson()
  echo "Testing: BookerOrg"
  testBookerOrg()
