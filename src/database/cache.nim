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

proc insert*(cache: var DocumentCache, doc: var BookerPerson) =
  var
    id = 1
    checkpoint: bool
  while checkpoint == false:
    if cache.people.contains(doc.id):
      if cache.people[doc.id].checkDiff(doc) == true:
        var ndoc = doc.upSert(cache.people[doc.id])
        cache.people[doc.id]= ndoc
        checkpoint = true
      else:
        doc.makeId(id)
    else:
      cache.people[doc.id]= doc
      checkpoint = true
    id += 1
proc insert*(cache: var DocumentCache, doc: var BookerEmail) =
  var checkpoint: bool
  while checkpoint == false:
    var ndoc = doc
    cache.emails[doc.id]= doc #emails should not conflict!
    checkpoint = true;

proc insert*(cache: var DocumentCache, doc: var BookerAddress) =
  var checkpoint: bool
  while checkpoint == false:
    if cache.locations.contains(doc.id):
      var ndoc = doc.upSert(cache.locations[doc.id])
      cache.locations[doc.id]= ndoc
      checkpoint = true
    else:
      discard cache.locations.put(doc.id, doc)
      checkpoint = true
proc insert*(cache: var DocumentCache, doc: var BookerOrg) =
  var checkpoint: bool
  while checkpoint == false:
    if cache.orgs.contains(doc.id):
      var ndoc = doc.upSert(cache.orgs[doc.id])
      cache.orgs[doc.id]= ndoc
      checkpoint = true
    else:
      discard cache.orgs.put(doc.id, doc)
      checkpoint = true
