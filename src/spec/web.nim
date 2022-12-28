import std/[options, strutils]
import uuids, documents

type
  BookerWebService* = ref object of BookerDocument
    port*: int
    url*: string
    host*: string
    service_name*: string
    service_version*: string

  BookerHost* = ref object of BookerDocument
    ip*: string
    hostname*: string
    operating_system*: string
    asn*: int
    country*: string
    network_name*: string
    owner*: string
    vulns*: seq[string]
    services*: seq[string]

  BookerCVE* = ref object of BookerDocument
    cve_number*: string
    score*: int


  BookerBreach* = ref object of BookerDocument
    total*: int
    description*: string
    url*: string


  BookerEmail* = ref object of BookerDocument
    ## A email address
    ## Owner and Password is Optional
    ## data_breach is used to track what breaches the email is part of
    email_username*: string
    email_domain*: string
    email_password*: string
    data_breach*: seq[string]
    eid*: string
  BookerEmailMessage* = ref object of BookerDocument
    ## a object represented as a email message
    body*: string
    subject*: string
    to*: string
    fromF*: string
    headers*: string
    cc*: seq[string]
    bcc*: seq[string]

  BookerUsername* = ref object of BookerDocument
    ## A object that represents a user
    url*: string # Url to the users page
    username*: string
    platform*: string
    phones*: seq[string]
    emails*: seq[BookerEmail]
    eid*: string

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
  var e = BookerEmail(email_username: emailData[0], email_domain: emailData[1])
  e.makeUUID()
  e.makeEID(e.email_password & e.email_domain)
  result = e

proc newEmail*(username, domain: string): BookerEmail =
  ## Create a new BookerEmail from username and domain
  var e = BookerEmail(email_username: username, email_domain: domain)
  e.makeUUID
  e.makeEID(e.email_password & e.email_domain)
  result = e

proc newEmail*(username, domain, password: string): BookerEmail =
  ## Create a new BookerEmail from username and domain with the leaked password
  var e = BookerEmail(email_username: username, email_domain: domain, email_password: password)
  e.makeUUID
  e.makeEID(e.email_password & e.email_domain)
  result = e

proc newUsername*(username, platform: string, url: string = ""): BookerUsername =
  BookerUsername(username: username, platform: platform)


proc newMessage*(message, group, platform: string, user: BookerUsername, channel="", message_id=""): BookerMessage =
  ## Create a new message from a instant messaging platform
  BookerMessage(message: message, platform: platform, group: group,
                user: user, message_id: message_id, channel: channel)


proc replyMessage*(source: var BookerMessage, dest: BookerMessage) =
  source.reply_to = some(dest)


proc replyMessage*(source: BookerMessage, dest: BookerMessage): BookerMessage =
  source.reply_to = some(dest)


proc getReply*(message: BookerMessage): BookerMessage =
  result = message.reply_to.get()
