import ../../src/starintel_doc/documents

proc testBaseDocument() =
  let time = now().toTime.toUnix
  echo "time is, ", $time
  var doc = BookerDocument(dataset: "Tests",
                            dtype: "test_doc", date_added: time, date_updated: time, id: "test")
  doAssert doc.dataset == "Tests"
  doAssert doc.dtype == "test_doc"
  doAssert doc.date_added == time
  doAssert doc.date_updated == time
  doAssert doc.id == "test"
