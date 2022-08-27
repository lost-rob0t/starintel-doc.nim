import std/[options, strutils]
import uuids, documents

type
  BookerWebService* = ref object of BookerDocument
    port*: int
    url*: Option[string]
    owner*: string
    host*: string
    service_name*: Option[string]
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
    email_password*: Option[string]
    data_breach*: seq[string]


  BookerEmailMessage* = ref object of BookerDocument
    ## a object represented as a email message
    body*: string
    subject*: Option[string]
    to*: string
    fromF*: string
    headers*: Option[string]
    cc*: seq[string]
    bcc*: seq[string]


  BookerMessage* = ref object of BookerDocument
    ## a object representing a instant message
    ## Use Booker EmailMessage For Email Content
    ## BookerSocialMPost for social media post
    message*: string
    platform*: string
    username*: string
    is_reply*: bool
    media*: bool
    mesage_id*: Option[string]
    reply_to*: Option[string]
    group*: string # if none assume dm chat
    channel*: Option[string] # for discord

  BookerUsername* = ref object of BookerDocument
    ## A object that represents a user
    url*: Option[string] # Url to the users page
    username*: string
    platform*: string
    phones*: seq[string]
    emails*: seq[BookerEmail]



proc newEmail*(email: string): BookerEmail =
  ## Take a email in the format of user@foo.bar and return a booker email
  let emailData = email.split("@")
  BookerEmail(email_username: emailData[0], email_domain: emailData[1])

proc newEmail*(email, password: string): BookerEmail =
  let emailData = email.split("@")
  BookerEmail(email_username: emailData[0],
              email_domain: emailData[1], email_password: some(password))

proc newUsername*(username, platform: string, url=none(string)): BookerUsername =
  BookerUsername(username: username, platform: platform)
