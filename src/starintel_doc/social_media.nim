import web
import documents, hashes
type
  BookerMessage* = ref object of BookerDocument
    ## a object representing a instant message
    ## Use Booker EmailMessage For Email Content
    ## BookerSocialMPost for social media post
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
    mentions*: seq[BookerUsername]

  BookerSocialMPost* = ref object of BookerDocument
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
proc newMessage*(message, group, platform: string, user: BookerUsername, channel="", message_id="", date: int64 = 0): BookerMessage =
  ## Create a new message from a instant messaging platform
  var doc = BookerMessage(message: message, platform: platform, group: group,
                          user: user.id, message_id: message_id, channel: channel, reply_to: "", dtype: "instant-message")
  result = doc


proc replyMessage*(source: var BookerMessage, dest: BookerMessage) =
  source.reply_to = dest.id


proc replyMessage*(source: BookerMessage, dest: BookerMessage): BookerMessage =
  source.reply_to = dest.id



proc hash(x: BookerSocialMPost): Hash =
  ## Create a hash for a Social media post
  ## Content is used, so updated versions of the post
  var h: Hash = 0
  h = h !& hash(x.content)
  h = h !& hash($x.date_added)
  h = h !& hash(x.title)
  h = h !& hash(x.group)
  h = h !& hash(x.url)
  result = !$h

proc newPost*(user: BookerUsername, content: string, title, group, url: string = "", date: int64 = 0): BookerSocialMPost =
  ## Create a New social media post
  var doc = BookerSocialMPost(user: user, content: content, title: title, group: group, url: url, dtype: "socialMPost")
  doc.makeMD5ID(content & url & $date)
  result = doc
