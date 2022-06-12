import mycouch
import asyncdispatch
import ../spec/documents
import cache
import json
import sugar
import lrucache
import tables
import sequtils
type
  AsyncStarintelDatabase*[T] = ref object of RootObj
    server*: AsyncCouchDBClient
    database*: string
    cache*: T


proc initStarIntel*(href, database: string, cacheSize=250, port=5984): AsyncStarintelDatabase[DocumentCache] =
    ## Create a new starintel-database client
    var cache = createCache(cache_size)
    var client = newAsyncCouchDBClient(host=href, port=port)

    result = AsyncStarintelDatabase[DocumentCache](server: client, cache: cache, database: database)

proc initStarIntel*(href, database: string, bufferSize=250, port=5984): AsyncStarintelDatabase[DocumentBuffer] =
    ## Create a new starintel-database client
    var cache = createBuffer(bufferSize)
    var client = newAsyncCouchDBClient(host=href, port=port)
    result = AsyncStarintelDatabase[DocumentBuffer](server: client, cache: cache, database: database)



proc login*(star: AsyncStarintelDataBase, username, pass: string) {.async.} =
  let x = await star.server.cookieAuth(name=username, password=pass)
  when defined(debug):
    echo $x
#proc bulkGet*(star: AsyncStarintelDatabase, database: string, docs: seq[BookerPerson]): Future[seq[JsonNode]] {.async.} =
#  var docids: seq[string]
#  when defined(debug):
#    echo %*docids
#  for d in docs:
#    docids.add(d.id)
#  when defined(debug):
#    echo "Bulk get from cache"
#    echo $docids
#  let rdocs = await star.server.bulkGet(database, %*docids)
#  for rdoc in rdocs["results"].items:
#      if rdoc["docs"]["error"].len != 0:
#        echo($rdoc["ok"].fixDoc)



proc insertEvict*(star: AsyncStarintelDatabase, doc: BookerPerson) {.async.} =
  ## Insert into the cache. If the cache is full upload the doc to the database
  if star.cache.people.isFull:
    let rdoc = star.cache.people.getLruValue
    let jdoc = %*rdoc
    jdoc{"_id"}= jdoc["id"]
    let resp = await star.server.createDoc(star.database, jdoc)
    when defined(debug):
      echo resp
    star.cache.people.del(rdoc.id)
    star.cache.people[doc.id] = doc
  else:
    star.cache.people[doc.id] = doc

proc insertEvict*(star: AsyncStarintelDatabase, doc: BookerOrg) {.async.} =
  ## Insert into the cache. If the cache is full upload the doc to the database
  if star.cache.orgs.isFull:
    let rdoc = star.cache.orgs.getLruValue
    let jdoc = %*rdoc
    jdoc{"_id"}= jdoc["id"]
    let resp = await star.server.createDoc(star.database, jdoc)
    when defined(debug):
      echo resp
    star.cache.orgs.del(rdoc.id)
    star.cache.orgs[doc.id] = doc
  else:
    star.cache.orgs[doc.id] = doc

proc insertEvict*(star: AsyncStarintelDatabase, doc: BookerAddress) {.async.} =
  ## Insert into the cache. If the cache is full upload the doc to the database
  if star.cache.locations.isFull:
    let rdoc = star.cache.people.getLruValue
    let jdoc = %*rdoc
    jdoc{"_id"}= jdoc["id"]
    let resp = await star.server.createDoc(star.database, jdoc)
    when defined(debug):
      echo resp
    star.cache.locations.del(rdoc.id)
    star.cache.locations[doc.id] = doc
  else:
    star.cache.locations[doc.id] = doc

proc insertEvict*(star: AsyncStarintelDatabase, doc: BookerEmail) {.async.} =
  ## Insert into the cache. If the cache is full upload the doc to the database
  if star.cache.emails.isFull:
    let rdoc = star.cache.emails.getLruValue
    let jdoc = %*rdoc
    jdoc{"_id"}= jdoc["id"]
    let resp = await star.server.createDoc(star.database, jdoc)
    when defined(debug):
      echo resp
    star.cache.emails.del(rdoc.id)
    star.cache.emails[doc.id] = doc
  else:
    star.cache.emails[doc.id] = doc

proc insertEvict*(star: AsyncStarintelDatabase, doc: BookerPhone) {.async.} =
  ## Insert into the cache. If the cache is full upload the doc to the database
  if star.cache.phones.isFull:
    let rdoc = star.cache.phones.getLruValue
    let jdoc = %*rdoc
    jdoc{"_id"}= jdoc["id"]
    let resp = await star.server.createDoc(star.database, jdoc)
    when defined(debug):
      echo resp
    star.cache.phones.del(rdoc.id)
    star.cache.phones[doc.id] = doc
  else:
    star.cache.phones[doc.id] = doc


proc clearDocumentBuffer*(star: AsyncStarintelDatabase) {.async.} =
  var docs = %[]
  for person in star.cache.people:
    docs.add(fixDoc(%*person))
  for org in star.cache.orgs:
    docs.add(fixDoc(%*org))
  for email in star.cache.emails:
    docs.add(fixDoc(%*email))
  for address in star.cache.locations:
    docs.add(fixDoc(%*address))
  for membership in star.cache.memberships:
    docs.add(fixDoc(%*membership))
  for phone in star.cache.phones:
    docs.add(fixDoc(%*phone))
  let resp = await star.server.bulkDocs(db=star.database, docs)
  when defined(debug):
    echo resp
    echo docs


proc getMemberships*[T](star: AsyncStarintelDatabase, doc: T): Future[seq[BookerMembership]] {.async.}=
  ## Get Memberships for a document
  var data = seq[BookerMembership]
  let resp = await star.server.bulkGet(star.database, %doc.memberships)
  for doc in resp["results"]:
    data.add(doc.fixDoc(mode="ingress").to(BookerMembership))
  result = data

proc updateMemberships*[T](memberships: seq[BookerMembership], docid: string, child, parent: bool): seq[BookerMembership] =
  ## Update the document refrence id.
  ## You spcify weather to update the child, or parent.
  assert child != parent
  result = memberships
  if child:
    for membership in result:
      membership.child = docid
  else:
    for membership in result:
      memberships.parent = docid

template handleBuffer*(star: AsyncStarintelDatabase, code: untyped): untyped =
  ## A simple template to handle the buffer
  if star.cache.len >= star.cache.max:
    await star.clearDocumentBuffer
    star.cache = clearBuffer(star.cache.max)
  else:
    code
