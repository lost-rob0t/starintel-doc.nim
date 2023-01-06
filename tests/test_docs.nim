import ../src/starintel_doc
import strutils
import options
import json, jsony

proc renameHook*(v: var BookerPerson, fieldName: var string) =
  if fieldName == "rev":
    fieldName = "_rev"
  if fieldName == "id":
    fieldName = "_id"
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
  doc.fname = "Joe"
  doc.mname = "l"
  doc.lname = "shmoe"
  echo doc.phones[0].phone
  assert doc.source_dataset == "Tests"
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
  echo doc.toJson
proc testBookerOrg() =
  var doc = newOrg(name="Star Intel", etype="Software")
  assert doc.name == "Star Intel"
  assert doc.etype == "Software"
  assert doc.eid.len > 0
  assert doc.id.len > 0
  echo doc.toJson
proc testBookerEmail() =
  let email = "test@foo.bar"
  var doc = newEmail(email)
  assert doc.email_username == "test"
  assert doc.email_domain == "foo.bar"
  assert doc.eid.len > 0
  assert doc.id.len > 0
  echo doc.toJson

  var doc1 = newEmail("test", "foo.bar")
  assert doc1.email_username == "test"
  assert doc1.email_domain == "foo.bar"
  assert doc1.eid.len > 0
  assert doc1.id.len > 0
  echo doc1.toJson

  var doc2 = newEmail("test", "foo.bar", "password")
  assert doc2.email_username == "test"
  assert doc2.email_domain == "foo.bar"
  assert doc2.email_password == "password"
  assert doc2.eid.len > 0
  assert doc2.id.len > 0
  echo doc2.toJson


proc testBookerUsername() =
  let doc = newUsername("user", "localhost")
  assert doc.url == ""
  assert doc.username == "user"
  assert doc.platform == "localhost"
  echo doc.toJson

proc testBookerMessage() =
  let message = "Wow Star intel is a really cool project!"
  let message1 = "Wow Star intel is a really awsome project!"
  var user = newUsername("user", "localhost")
  var doc = newMessage(message=message, platform="irc", group="#star-intel-irc", user=user)
  var doc1 = newMessage(message=message1, platform="irc", group="#star-intel-irc", user=user)
  assert doc.message == message
  assert doc.user == user
  assert doc.platform == "irc"
  assert doc.group == "#star-intel-irc"
  assert doc.message_id == ""
  assert doc.message_id == ""
  assert doc.is_reply == false
  doc.reply_to = doc1
  let doc3 = doc.getReply
  assert doc3.message == message1
  echo %*doc
  echo doc1.toJson
  echo doc3.toJson

proc testBookerTarget() =
  let target = "nsaspy"
  let dataset = "git accounts"
  let actor = "GitBot"
  var doc = newTarget(dataset, target, actor)
  assert doc.target == target
  assert doc.dataset == dataset
  assert doc.actor == actor
  echo doc.id
  echo doc.toJson
proc testRelation() =
  let sourceId = "testfoobar"
  let targetId = "testbarfoo"
  var doc = newRelation(source=sourceId, target=targetId, relation = Relations.to)
  assert doc.source == sourceId
  assert doc.target == targetId
  assert doc.relation == Relations.to
  echo $doc.toJson

proc testSocialMediaPost() =
  let author = newUsername("nsaspy", "github", "https://github.com/lost-rob0t")
  let m = "Starintel is simply and flexable for any osint project!"
  let m1 = "Yes im going to patch support for other tools i use!"
  let author1 = newUsername("cia", "cia.gov")
  var doc = author.newPost(m)
  doc.replies.add(author1.newPost(m1))
  assert doc.user == author
  assert doc.content == m
  assert doc.replies[0].content == m1
  assert doc.replies[0].user == author1
  echo doc.toJson
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
  echo "Testing BookerRelations"
  testRelation()
  echo "Testing BookerSocialMPost"
  testSocialMediaPost()
