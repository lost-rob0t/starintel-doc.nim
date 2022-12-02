import ../src/starintel_doc
import strutils
import options

proc testBookerDoc() =
  var doc = BookerDocument(dataset: "Tests",
                            dtype: "test_doc", date_added: "test", date_updated: "test", id: "test")
  assert doc.dataset == "Tests"
  assert doc.dtype == "test_doc"
  assert doc.date_added == "test"
  assert doc.date_updated == "test"
  assert doc.id == "test"

proc testBookerPerson() =
  var doc = BookerPerson(dataset: "Tests", dtype: "person",
                         date_added: "test", date_updated: "test", id: "test")
  var phone = newPhone("1234567890")
  link[BookerPerson, BookerPhone](doc, doc.phones, phone)
  doc.fname = "Joe"
  doc.mname = "l"
  doc.lname = "shmoe"
  echo doc.phones[0].phone
  assert doc.dataset == "Tests"
  assert doc.dtype == "person"
  assert doc.date_added == "test"
  assert doc.date_updated == "test"
  assert doc.id == "test"

  doc.makeUUID
  assert doc.id.len > 10
  assert doc.fname == "Joe"
  assert doc.mname == "l"
  assert doc.lname == "shmoe"

proc testBookerOrg() =
  var doc = newOrg(name="Star Intel", etype="Software")
  assert doc.name == "Star Intel"
  assert doc.etype == "Software"
  assert doc.eid.len > 0
  assert doc.id.len > 0
proc testBookerEmail() =
  let email = "test@foo.bar"
  var doc = newEmail(email)
  assert doc.email_username == "test"
  assert doc.email_domain == "foo.bar"
  assert doc.id.len > 0

  var doc1 = newEmail("test", "foo.bar")
  assert doc1.email_username == "test"
  assert doc1.email_domain == "foo.bar"
  assert doc.id.len > 0


  var doc2 = newEmail("test", "foo.bar", "password")
  assert doc2.email_username == "test"
  assert doc2.email_domain == "foo.bar"
  assert doc2.email_password == "password"
  assert doc.eid.len > 0
  assert doc.id.len > 0



proc testBookerUsername() =
  let doc = newUsername("user", "localhost")
  assert doc.url == ""
  assert doc.username == "user"
  assert doc.platform == "localhost"

proc testBookerMessage() =
  let message = "Wow Star intel is a really cool project!"
  var user = newUsername("user", "localhost")
  let doc = newMessage(message=message, platform="irc", group="#star-intel-irc", user=user)
  assert doc.message == message
  assert doc.user == user
  assert doc.platform == "irc"
  assert doc.group == "#star-intel-irc"
  assert doc.message_id == ""
  assert doc.message_id == ""
  assert doc.is_reply == false
  var doc1 = doc
  doc1.replyMessage(doc)
  let doc3 = doc1.getReply
  assert doc3.message == message

proc testBookerTarget() =
  let target = "nsaspy"
  let dataset = "git accounts"
  let actor = "GitBot"
  var doc = newTarget(dataset, target, actor)
  assert doc.target == target
  assert doc.dataset == dataset
  assert doc.actor == actor

when isMainModule:
  echo "Testing: BookerDocument"
  testBookerDoc()
  echo "Testing: BookerPerson"
  testBookerPerson()
  echo "Testing: BookerOrg"
  testBookerOrg()
  echo "Testing: BookerEmail"
  testBookerEmail()
  echo "Testing: BookerUsername"
  testBookerUsername()
  echo "Testing: BookerMessage"
  testBookerMessage()
  echo "Testing: BookerTarget"
  testBookerTarget()
