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
    user*: BookerUsername
    is_reply*: bool
    media*: seq[string]
    message_id*: string
    reply_to*: BookerMessage
    group*: string # if none assume dm chat
    channel*: string # for discord
    mentions*: seq[BookerUsername]

  BookerSocialMPost* = ref object of BookerDocument
    ## An Object Representing a social media post, Such as on reddit, mastodon, 4chan, ect
    content*: string
    user*: BookerUsername
    replies*: seq[BookerSocialMPost] ## Used when you have the complete reply chain.
    media*: seq[string]
    replyCount*: int
    repostCount*: int
    url*: string
    links*: seq[string]
    tags*: seq[string]
    isReply*: bool
    # NOTE are keeping track of these also needed?
    title*: string
    group*: string
    # NOTE: How Should i keep tracks of older versions?
    #XXX nsaspy <2023-01-20 Fri> You dont. Each document is to be treated as a snapshot in time.
    replyTo*: BookerSocialMPost ## Linked List, when isReply is false, assume you are at the last of the replies
proc newMessage*(message, group, platform: string, user: BookerUsername, channel="", message_id=""): BookerMessage =
  ## Create a new message from a instant messaging platform
  var doc = BookerMessage(message: message, platform: platform, group: group,
                          user: user, message_id: message_id, channel: channel, reply_to: BookerMessage())
  result = doc


proc replyMessage*(source: var BookerMessage, dest: BookerMessage) =
  source.reply_to = dest


proc replyMessage*(source: BookerMessage, dest: BookerMessage): BookerMessage =
  source.reply_to = dest


proc getReply*(message: BookerMessage): BookerMessage =
  result = message.reply_to

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

proc newPost*(user: BookerUsername, content: string, title, group, url: string = ""): BookerSocialMPost =
  ## Create a New social media post
  var doc = BookerSocialMPost(user: user, content: content, title: title, group: group, url: url)
  doc.id = $doc.hash
  result = doc
