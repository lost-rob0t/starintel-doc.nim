import web
import documents, hashes
type
  Message* = ref object of Document
    ## a object representing a instant message
    ## Use  EmailMessage For Email Content
    ## SocialMPost for social media post
    ## This is a link list of sorts
    ## Just check the reply_to field until it is empty
    # TODO add iterator to traverse replys
    message*: string
    platform*: string
    user*: string # Link to the user doc
    is_reply*: bool
    media*: seq[string]
    message_id*: string
    reply_to*: string # Link to the reply.
    group*: string # if none assume dm chat
    channel*: string # for discord
    mentions*: seq[string]

  SocialMPost* = ref object of Document
    ## An Object Representing a social media post, Such as on reddit, mastodon, 4chan, ect
    content*: string
    user*: string
    replies*: seq[string] ## Used when you have the complete reply chain.
    media*: seq[string]
    replyCount*: int
    repostCount*: int
    url*: string
    links*: seq[string]
    tags*: seq[string]
    # NOTE are keeping track of these also needed?
    # XXX nsaspy <2023-02-04 Sat> Yes group and title can be usedd for reddit but no bots exist as of writing
    title*: string
    group*: string
    replyTo*: string ## Linked List, when isReply is false, assume you are at the last of the replies
proc newMessage*(message, group, platform: string, user: User, channel="", message_id="", date: int64 = 0): Message =
  ## Create a new message from a instant messaging platform
  var doc = Message(message: message, platform: platform, group: group,
                          user: user.name, message_id: message_id, channel: channel, reply_to: "", dtype: "instant-message")
  result = doc

proc newMessage*(message, group, platform: string, user: string, channel="", message_id="", date: int64 = 0): Message =
  ## Create a new message from a instant messaging platform
  var doc = Message(message: message, platform: platform, group: group,
                          user: user, message_id: message_id, channel: channel, reply_to: "", dtype: "instant-message")
  result = doc



proc replyMessage*(source: var Message, dest: Message) =
  source.reply_to = dest.id


proc replyMessage*(source: Message, dest: Message): Message =
  source.reply_to = dest.id



proc hash(x: SocialMPost): Hash =
  ## Create a hash for a Social media post
  ## Content is used, so updated versions of the post
  var h: Hash = 0
  h = h !& hash(x.content)
  h = h !& hash($x.date_added)
  h = h !& hash(x.title)
  h = h !& hash(x.group)
  h = h !& hash(x.url)
  result = !$h

proc newPost*(user: User, content: string, title, group, url: string = "", date: int64 = 0): SocialMPost =
  ## Create a New social media post
  var doc = SocialMPost(user: user.name, content: content, title: title, group: group, url: url, dtype: "socialMPost")
  doc.makeMD5ID(content & url & $date)
  result = doc
proc newPost*(user: string, content: string, title, group, url: string = "", date: int64 = 0): SocialMPost =
  ## Create a New social media post
  var doc = SocialMPost(user: user, content: content, title: title, group: group, url: url, dtype: "socialMPost")
  doc.makeMD5ID(content & url & $date)
  result = doc
