import documents, phones
import json, strutils

type
  Breach* = ref object of Document
    total*: int
    description*: string
    url*: string

  Email* = ref object of Document
    ## A email address
    ## Owner and Password is Optional
    ## data_breach is used to track what breaches the email is part of
    user*: string
    domain*: string
    password*: string

  EmailMessage* = ref object of Document
    ## a object represented as a email message
    body*: string
    subject*: string
    to*: string
    # FIXME Bad name fromF
    fromF*: string
    headers*: string
    cc*: seq[string]
    bcc*: seq[string]


  # HACK Improve this
  # the misc field seems like a bad idea?
  # whatever it should be a raw json node is a bad idea, maybe it should be just json as a string.
  User* = ref object of Document
    ## A object that represents a user
    url*: string # Url to the users page
    name*: string
    platform*: string
    misc*: seq[JsonNode]
    bio*: string


proc newEmail*(email: string): Email =
  ## Take a email in the format of user@foo.bar and return a booker email
  let emailData = email.split("@")
  var e = Email(user: emailData[0], domain: emailData[1], dtype: "email")
  e.makeMD5ID(e.password & e.domain & e.user)
  result = e

proc newEmail*(user, domain: string): Email =
  ## Create a new Email from user and domain
  var e = Email(user: user, domain: domain, dtype: "email")
  e.makeMD5ID(e.user & e.domain)
  result = e

proc newEmail*(user, domain, password: string): Email =
  ## Create a new Email from user and domain with the leaked password
  var e = Email(user: user, domain: domain, password: password, dtype: "email")
  e.makeMD5ID(e.user & e.domain & e.password)
  result = e


proc newUser*(username, platform: string, url: string = ""): User =
  var doc = User(name: username, platform: platform, url: url, dtype: "user")
  doc.makeMD5ID(username & url)
  result = doc
# TODO hash procs for username and email docs, uuids are deprecated


proc newUsername*(username, platform: string, url: string = ""): User =
  result = newUser(username, platform, url)
# TODO hash procs for username and email docs, uuids are deprecated
