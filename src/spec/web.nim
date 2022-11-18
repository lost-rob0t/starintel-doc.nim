import std/[options, strutils]
import uuids, documents
import json
type
  BookerWebDocument* = ref object of RootObj
    eid*: string
    id*: string
    rev*: string
    dataset*: string
    date*: string
    dtype*: string
  BookerWebService* = ref object of BookerWebDocument
    port*: int
    url*: Option[string]
    host*: string
    service_name*: Option[string]
    service_version*: string
  BookerHost* = ref object of BookerWebDocument
    ip*: string
    hostname*: string
    operating_system*: string
    asn*: int
    country*: string
    network_name*: string
    owner*: string
    vulns*: seq[string]
    services*: seq[string]
  BookerCVE* = ref object of BookerWebDocument
    cve_number*: string
    score*: int


  BookerBreach* = ref object of BookerWebDocument
    total*: int
    description*: string
    url*: string

  BookerEmail* = ref object of BookerWebDocument
    ## A email address
    ## Owner and Password is Optional
    ## data_breach is used to track what breaches the email is part of
    email_username*: string
    email_domain*: string
    email_password*: string
    data_breach*: seq[string]
  BookerEmailMessage* = ref object of BookerWebDocument
    ## a object represented as a email message
    body*: string
    subject*: Option[string]
    to*: string
    fromF*: string
    headers*: Option[string]
    cc*: seq[string]
    bcc*: seq[string]
  BookerUsername* = ref object of BookerWebDocument
    ## A object that represents a user
    url*: string # Url to the users page
    username*: string
    platform*: string
    phones*: seq[string]
    emails*: seq[BookerEmail]
    misc*: seq[JsonNode]
    bio*: string
  BookerMessage* = ref object of BookerWebDocument
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
    media*: bool
    message_id*: string
    reply_to*: BookerMessage
    group*: string # if none assume dm chat
    channel*: string # for discord
    owner*: BookerUsername
    mentions*: seq[BookerUsername]


proc newEmail*(email: string): BookerEmail =
  ## Take a email in the format of user@foo.bar and return a booker email
  let emailData = email.split("@")
  var e = BookerEmail(email_username: emailData[0], email_domain: emailData[1], dtype: "email")
  e.makeUUID()
  e.makeEID(email)
  result = e

proc newEmail*(username, domain: string): BookerEmail =
  ## Create a new BookerEmail from username and domain
  var e = BookerEmail(email_username: username, email_domain: domain, dtype: "email")
  e.makeUUID
  e.makeEID(e.email_username & e.email_domain)
  result = e

proc newEmail*(username, domain, password: string): BookerEmail =
  ## Create a new BookerEmail from username and domain with the leaked password
  var e = BookerEmail(email_username: username, email_domain: domain, email_password: password, dtype: "email")
  e.makeUUID
  e.makeEID(e.email_username & e.email_domain & e.email_password)
  result = e

proc newUsername*(username, platform: string, url=""): BookerUsername =
  var u = BookerUsername(username: username, platform: platform, dtype: "username")
  u.makeEID(u.username)
  u.makeUUID
  result = u

proc newMessage*(message, group, platform: string, user: BookerUsername, channel="", message_id=""): BookerMessage =
  ## Create a new message from a instant messaging platform
  BookerMessage(message: message, platform: platform, group: group,
                user: user, message_id: message_id, channel: channel, dtype: "message")


proc replyMessage*(source: var BookerMessage, dest: BookerMessage) =
  source.reply_to = dest

proc replyMessage*(source: BookerMessage, dest: BookerMessage): BookerMessage =
  source.reply_to = dest

proc getReply*(message: BookerMessage): BookerMessage =
  result = message.reply_to
