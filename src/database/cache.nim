import lrucache
import ../spec/documents
import mycouch
import json

type
  DocumentCache* = ref object
    orgs*: LruCache[string, BookerOrg]
    people*: LruCache[string, BookerPerson]
    locations*: LruCache[string, BookerAddress]
    emails*: LruCache[string, BookerEmail]
    memberships*: LruCache[string, BookerMembership]

  using:
    CC: CouchDBClient
    ACC: AsyncCouchDBClient

proc upSert*(doc1, doc2: BookerPerson): BookerPerson =
  ## Insert new data only and return document
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      doc1.memberships.add(membership)
  for address in doc1.address:
    if address notin doc2.address:
      doc1.address.add(address)
  for email in doc1.emails:
    if email notin doc2.emails:
      doc1.emails.add(email)
  return doc1

proc upSert*(doc1, doc2: BookerAddress): BookerAddress =
  ## Insert new data only and return document
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      doc1.memberships.add(membership)
  return doc1
proc upSert*(doc1, doc2: var BookerOrg): BookerOrg =
  ## Insert new data only and return document
  for membership in doc1.memberships:
    if membership notin doc2.memberships:
      doc1.memberships.add(membership)
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
        cache.people[doc.id] = ndoc
        checkpoint = true
      else:
        doc.makeId(id)
    else:
      discard cache.people.put(doc.id, doc)
      checkpoint = true
    id += 1
proc insert*(cache: var DocumentCache, doc: var BookerEmail) =
  var checkpoint: bool
  while checkpoint == false:
    discard cache.emails.getOrPut(doc.id, doc) #emails should not conflict!
    checkpoint = true;

proc insert*(cache: var DocumentCache, doc: var BookerAddress) =
  var checkpoint: bool
  while checkpoint == false:
    if cache.locations.contains(doc.id):
      cache.locations[doc.id] = cache.locations[doc.id].upSert(doc)
      checkpoint = true
    else:
      discard cache.locations.put(doc.id, doc)
      checkpoint = true


