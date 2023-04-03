import documents, phones
import uuids
import json, strutils
type
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
    phones*: seq[BookerPhone]
    emails*: seq[BookerEmail]
    misc*: seq[JsonNode]
    bio*: string


proc newEmail*(email: string): BookerEmail =
  ## Take a email in the format of user@foo.bar and return a booker email
  let emailData = email.split("@")
  var e = BookerEmail(email_username: emailData[0], email_domain: emailData[1], dtype: "email")
  e.makeMD5ID(e.email_password & e.email_domain)
  result = e

proc newEmail*(username, domain: string): BookerEmail =
  ## Create a new BookerEmail from username and domain
  var e = BookerEmail(email_username: username, email_domain: domain, dtype: "email")
  e.makeMD5ID(e.email_username & e.email_domain)
  result = e

proc newEmail*(username, domain, password: string): BookerEmail =
  ## Create a new BookerEmail from username and domain with the leaked password
  var e = BookerEmail(email_username: username, email_domain: domain, email_password: password, dtype: "email")
  e.makeMD5ID(e.email_username & e.email_domain & e.email_password)
  result = e


proc newUsername*(username, platform: string, url: string = ""): BookerUsername =
  var doc = BookerUsername(username: username, platform: platform, url: url, dtype: "user")
  doc.makeMD5ID(username & url)
  result = doc
# TODO hash procs for username and email docs, uuids are deprecated
