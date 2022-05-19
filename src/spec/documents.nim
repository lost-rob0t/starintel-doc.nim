import std/[jsonutils, hashes, tables, json, options, sequtils, strutils]
import urand
import libsha / sha256
var Joptions*: Joptions
Joptions.allowMissingKeys = true
Joptions.allowExtraKeys = true
const
  ORG_WEIGHT = 5
  ADDRESS_WEIGHT = 5
  EMAIL_WEIGHT = 0
  POL_WEIGHT = 0
  IP_WEIGHT = 0
  EDUCATION_WEIGHT = 0
  GENDER_WEIGHT = 0
  AGE_WEIGHT = 0
  DOB_WEIGHT = 0
  SOCIAL_WEIGHT = 0
  MAX_SCORE = ORG_WEIGHT + ADDRESS_WEIGHT + EMAIL_WEIGHT
  THRESHOLD = 0.6
type
    BookerDocument* = ref object of RootObj
      ## Base Object to hold the document metadata thats used to make a dcoument and store it in couchdb
      ## _id and _rev are renamed to id and rev due to limitations of nim.
      operation_id*: int
      id*: string
      rev*: Option[string]
      owner_id*: Option[int]
      source_dataset*: string
      dataset*: string
      `type`*: string
      memberships*: seq[string]
      date_added*: string
      date_updated*: string

    BookerPerson* = ref object of BookerDocument
      ## A object that represents a person in starvar intel
      ## NOTE: person is merged with member and member is no longer used
      fname*: Option[string]
      mname*: Option[string]
      lname*: Option[string]
      bio*: Option[string]
      dob*: Option[string]
      age*: Option[int]
      social_media*:  seq[string]
      phones*: seq[string]
      emails*: seq[string]
      address*: seq[string]
      ip*: seq[string]
      orgs*: seq[string]
      education*: seq[string]
      comments*:  seq[string]
      gender*: Option[string]
      political_party*: Option[string]



    BookerOrg* = ref object of BookerDocument
      ## An object that represents a compnay or organization
      name*: string
      bio*: Option[string]
      country*: Option[string]
      reg_number*: Option[string]
      address*: seq[string]
      email_formats*: seq[string]
      organization_type*: Option[string]

    BookerAddress* = ref object of BookerDocument
      ## An address. Do not use to represent a reigon!
      ## may only work for us postal system
      ## Members is a seq of document id that point to other people or org docs.
      street*: string
      city*: string
      state*: string
      zip*: string
      apt*: Option[string]

    BookerEmail* = ref object of BookerDocument
      ## A email address
      ## Owner and Password is Optional
      ## data_breach is used to track what breaches the email is part of
      email_username*: string
      email_domain*: string
      email_password*: Option[string]
      data_breach*: seq[string]
      owner*: Option[string]
      username*: Option[string] # points to the owner


    BookerPhone* = ref object of BookerDocument
      ## A Phone number
      phone*: string
      owner*: Option[string]
      carrier*: Option[string]
      status*: Option[string]
      phone_type*: Option[string]


    BookerUsername* = ref object of BookerDocument
      ## A object that represents a user
      url*: Option[string] # Url to the users page
      username*: string
      platform*: string
      phones*: seq[string]
      emails*: seq[string]
      orgs*: seq[string]
      owner*: string

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

    BookerEmailMessage* = ref object of BookerDocument
      ## a object represented as a email message
      body*: string
      subject*: Option[string]
      to*: string
      `from`*: string
      headers*: Option[string]
      cc*: seq[string]
      bcc*: seq[string]

    BookerMembership* = ref object of BookerDocument
      ## Document holding metadata linking two documents
      title*: string
      roles*: seq[string]
      start_date*: string
      end_date*: string
      child*: string
      parent*: string


    BookerBreach* = ref object of BookerDocument
      total*: int
      description*: string
      url*: string

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

proc makeHash*(input: string): string =
  let sha = newSha256()
  sha.add(input)
  result = $sha.hexdigest()

proc makeId*(doc: var BookerPerson, id=0) =
  ## Create a sha256 uuid.
  ## if document with uuid exists increment id until a unique uuid is found
  ## Think of it like a john smith + 1, john smith + 2, ect
  doc.id = makeHash(doc.fname.get(" ") & doc.mname.get(" ") & doc.lname.get(" ") & $id)

proc makeId*(doc: BookerOrg) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.name & doc.country.get(" "))

proc makeId*(doc: BookerEmail) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.email_username & doc.email_domain)

proc makeId*(doc: BookerAddress) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.street & doc.city & doc.state & doc.zip)

proc makeId*(doc: BookerPhone) =
  ## Create a sha256 uuid.
  ## There may be many of the same phone number
  ## UUID here is based on the owner id and phone number
  doc.id = makeHash(doc.phone & doc.owner.get(" "))


proc makeId*(doc: BookerUsername) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.username & doc.platform)

proc makeId*(doc: BookerMessage) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.username & doc.channel.get(" ") & doc.group & doc.date_added)

proc makeId*(doc: BookerEmailMessage) =
  ## Create a uuid for the document
  var ur: Urand
  ur.open()
  doc.id = makeHash($ur.urand(128))

proc makeId*(doc: BookerMembership) =
  ## Create a uuid for the document
  var ur: Urand
  ur.open()
  defer: ur.close()
  doc.id = makeHash($ur.urand(128))


proc makeId*(doc: BookerBreach) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.url & $doc.total)

proc makeId*(doc: BookerWebService) =
  ## Create a sha256 uuid.
  doc.id = makeHash($doc.port & doc.host & doc.service_name.get(" "))

proc makeId*(doc: BookerHost) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.ip & doc.hostname & $doc.asn)

proc makeId*(doc: BookerCVE) =
  ## Create a sha256 uuid.
  doc.id = makeHash(doc.cve_number)

proc fixDoc*(doc: JsonNode ): JsonNode =
  ## adds the _rev and _id fields
  ## this is becuase of a limitation of nim
  doc["_id"] = doc["id"]
  doc.delete("id")
  if doc["rev"].len > 0:
    doc["_rev"] = doc["rev"]
    doc.delete("rev")
  result = doc


proc checkDiff*(doc1, doc2: BookerPerson): bool =
  ## Checks if 2 BookerPerson docs are simlar.
  ## if 1 field matches return true
  var score: int
  for address in doc1.address:
    if address in doc2.address:
      score += ADDRESS_WEIGHT

  # Why doesnt this work
  # TODO fixme
  for email in doc1.emails:
    if email in doc2.emails:
      score += EMAIL_WEIGHT
  if doc1.gender == doc2.gender:
    score += GENDER_WEIGHT
  for social in doc1.social_media:
    if social in doc2.social_media:
      score += SOCIAL_WEIGHT

  for org in doc1.orgs:
    if org in doc2.orgs:
      score += ORG_WEIGHT



  let fuzz = score / MAX_SCORE
  if fuzz >= THRESHOLD:
    return true
  else:
    return false

proc docInsertNew*(doc1, doc2: BookerPerson) =
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      doc1.memberships.add(membership)
  for address in doc1.address:
    if address notin doc2.address:
      doc1.address.add(address)
  #TODO fix me
  for email in doc1.emails:
    if email notin doc2.emails:
      doc1.emails.add(email)

proc docInsertNew*(doc1, doc2: BookerAddress) =
   for membership in doc1.memberships:
    if membership notin doc2.memberships:
      doc1.memberships.add(membership)
