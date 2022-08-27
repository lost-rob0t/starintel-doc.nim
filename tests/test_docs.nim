import ../src/starintel_doc
import strutils
import options
proc testBookerDoc() =
  var doc = BookerDocument(source_dataset: "Tests", dataset: "Tests",
                            dtype: "test_doc", date_added: "test", date_updated: "test", id: "test")
  assert doc.source_dataset == "Tests"
  assert doc.dataset == "Tests"
  assert doc.dtype == "test_doc"
  assert doc.date_added == "test"
  assert doc.date_updated == "test"
  assert doc.id == "test"

proc testBookerPerson() =
  var doc = BookerPerson(source_dataset: "Tests", dataset: "Tests", dtype: "person",
                         date_added: "test", date_updated: "test", id: "test")
  var phone = newPhone("1234567890")
  link[BookerPerson, BookerPhone](doc, doc.phones, phone)
  doc.fname = some("Joe")
  doc.mname = some("l")
  doc.lname = some("shmoe")
  echo doc.phones[0].phone
  assert doc.source_dataset == "Tests"
  assert doc.dataset == "Tests"
  assert doc.dtype == "person"
  assert doc.date_added == "test"
  assert doc.date_updated == "test"
  assert doc.id == "test"

  doc.makeUUID
  assert doc.id.len > 10
  assert doc.fname == some("Joe")
  assert doc.mname == some("l")
  assert doc.lname == some("shmoe")

proc testBookerOrg() =
  # TODO
  discard

proc testBookerEmail() =
  let email = "test@foo.bar"
  var doc = newEmail(email)
  assert doc.email_username == "test"
  assert doc.email_domain == "foo.bar"
  var docp = newEmail(email, "password")
  assert docp.email_username == "test"
  assert docp.email_domain == "foo.bar"
  assert docp.email_password == some("password")

when isMainModule:
  testBookerDoc()
  testBookerPerson()
  testBookerEmail()
