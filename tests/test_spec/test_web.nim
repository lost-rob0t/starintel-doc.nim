import ../../src/starintel_doc
import times
import json

proc testEmail() =
  let email = "test@foo.bar"
  var doc = newEmail(email)
  doAssert doc.email_username == "test"
  doAssert doc.email_domain == "foo.bar"
  doAssert doc.id.len > 0
  doAssert doc.dtype == "email"

  var doc1 = newEmail("test", "foo.bar")
  doAssert doc1.email_username == "test"
  doAssert doc1.email_domain == "foo.bar"
  doAssert doc.id.len > 0
  doAssert doc1.id.len > 0
  var doc2 = newEmail("test", "foo.bar", "password")
  doAssert doc2.email_username == "test"
  doAssert doc2.email_domain == "foo.bar"
  doAssert doc2.email_password == "password"
  doAssert doc2.id.len > 0


proc testUsername() =
  var doc = newUser("user", "localhost", "http://127.0.0.1")
  var doc1 = newUsername("user", "localhost", "http://127.0.0.1") # keep old functionality i like this name
  doc.bio = "He is the local host user!"
  doc.misc.add(%*{"foo": "bar"})
  doAssert doc.url == "http://127.0.0.1"
  doAssert doc.name == "user"
  doAssert doc.platform == "localhost"
  doAssert doc.bio == "He is the local host user!"
  doAssert doc.misc[0]["foo"].getStr == "bar"
  doAssert doc.dtype == "user"
when isMainModule:
  echo "testing: Email"
  testEmail()
  echo "testing: Username"
  testUsername()
