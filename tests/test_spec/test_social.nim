import ../../src/starintel_doc/social_media
import ../../src/starintel_doc/web



proc testBookerMessage() =
  let message = "Wow Star intel is a really cool project!"
  let message1 = "Wow Star intel is a really awsome project!"
  var user = newUsername("user", "localhost")
  var doc = newMessage(message=message, platform="irc", group="#star-intel-irc", user=user)
  var doc1 = newMessage(message=message1, platform="irc", group="#star-intel-irc", user=user)
  doc1.replyMessage(doc)
  assert doc.message == message
  assert doc.user == user.id
  assert doc.platform == "irc"
  assert doc.group == "#star-intel-irc"
  assert doc.message_id == ""
  assert doc.message_id == ""
  assert doc.is_reply == false

proc testSocialMediaPost() =
  let author = newUsername("nsaspy", "github", "https://github.com/lost-rob0t")
  let m = "Starintel is simply and flexable for any osint project!"
  let m1 = "Yes im going to patch support for other tools i use!"
  let author1 = newUsername("cia", "cia.gov")
  var doc = author.newPost(m)
  let post1 = author1.newPost(m1)
  doc.replies.add(post1.id)
  assert doc.user == author.id
  assert doc.content == m
  assert doc.replies[0] == post1.id

when isMainModule:
  echo "testing: BookerMessage"
  testBookerMessage()
  echo "testing: BookerSocialMediaPost"
  testSocialMediaPost()
