import lrucache
import ../spec/documents
import mycouch
import json
import sequtils
type
  DocumentCache* = ref object
    orgs*: LruCache[string, BookerOrg]
    people*: LruCache[string, BookerPerson]
    locations*: LruCache[string, BookerAddress]
    emails*: LruCache[string, BookerEmail]
    memberships*: LruCache[string, BookerMembership]
    phones*: LruCache[string, BookerPhone]

  DocumentBuffer* = ref object
    orgs*: seq[BookerOrg]
    people*: seq[BookerPerson]
    emails*: seq[BookerEmail]
    phones*: seq[BookerPhone]
    locations*: seq[BookerAddress]
    memberships*: seq[BookerMembership]
    max*: int

proc upSert*(doc1, doc2: BookerPerson): BookerPerson =
  ## TODO add rev update
  ## Insert new data only and return document
  var nm: seq[string]
  var na: seq[string]
  var ne: seq[string]
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      nm.add(membership)
  for address in doc1.address:
    if address notin doc2.address:
      na.add(address)
  for email in doc1.emails:
    if email notin doc2.emails:
      ne.add(email)
  doc1.memberships = concat(doc1.memberships, nm)
  doc1.address = concat(doc1.address, na)
  doc1.emails = concat(doc1.emails, na)
  return doc1

proc upSert*(doc1, doc2: BookerAddress): BookerAddress =
  ## Insert new data only and return document
  var nm: seq[string]
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      nm.add(membership)
  doc1.memberships = concat(nm, doc1.memberships)
  return doc1

proc upSert*(doc1, doc2:  BookerOrg): BookerOrg =
  ## Insert new data only and return document
  var nm: seq[string]
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      nm.add(membership)
  doc1.memberships = concat(nm, doc1.memberships)
  return doc1

proc createCache*(size: int): DocumentCache =
  ## initalize cache with size
  var d = DocumentCache()
  d.orgs = newLRUCache[string, BookerOrg](size)
  d.people = newLRUCache[string, BookerPerson](size)
  d.locations = newLRUCache[string, BookerAddress](size)
  d.emails = newLRUCache[string, BookerEmail](size)
  d.memberships = newLRUCache[string, BookerMembership](size)
  result = d

proc createBuffer*(size: int): DocumentBuffer =
  result = DocumentBuffer()
  result.max = size


proc len*(buffer: DocumentBuffer): int =
  let result = buffer.people.len + buffer.emails.len + buffer.phones.len + buffer.orgs.len + buffer.locations.len + buffer.memberships.len

proc clearBuffer*(size: int): DocumentBuffer =
  result = createBuffer(size)
