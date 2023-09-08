import documents, phones
import uuids
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
    email_username*: string
    email_domain*: string
    email_password*: string

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


  Username* = ref object of Document
    ## A object that represents a user
    url*: string # Url to the users page
    username*: string
    platform*: string
    misc*: seq[JsonNode]
    bio*: string


proc newEmail*(email: string): Email =
  ## Take a email in the format of user@foo.bar and return a booker email
  let emailData = email.split("@")
  var e = Email(email_username: emailData[0], email_domain: emailData[1], dtype: "email")
  e.makeMD5ID(e.email_password & e.email_domain)
  result = e

proc newEmail*(username, domain: string): Email =
  ## Create a new Email from username and domain
  var e = Email(email_username: username, email_domain: domain, dtype: "email")
  e.makeMD5ID(e.email_username & e.email_domain)
  result = e

proc newEmail*(username, domain, password: string): Email =
  ## Create a new Email from username and domain with the leaked password
  var e = Email(email_username: username, email_domain: domain, email_password: password, dtype: "email")
  e.makeMD5ID(e.email_username & e.email_domain & e.email_password)
  result = e


proc newUsername*(username, platform: string, url: string = ""): Username =
  var doc = Username(username: username, platform: platform, url: url, dtype: "user")
  doc.makeMD5ID(username & url)
  result = doc
# TODO hash procs for username and email docs, uuids are deprecated
