import mycouch
import asyncdispatch
import ../spec/documents
import cache
import json
import sugar
import lrucache
import tables
type
  AsyncStarintelDatabase* = ref object of RootObj
    server*: AsyncCouchDBClient
    database*: string
    cache*: DocumentCache


proc initStarIntel*(href, database: string, cacheSize=250, port=5984): AsyncStarintelDatabase =
    ## Create a new starintel-database client
    var cache = createCache(cache_size)
    var client = newAsyncCouchDBClient(host=href, port=port)

    result = AsyncStarintelDatabase(server: client, cache: cache, database: database)

proc login*(star: AsyncStarintelDataBase, username, pass: string) {.async.} =
  let x = await star.server.cookieAuth(name=username, password=pass)
  when defined(debug):
    echo $x
proc bulkGet*(star: AsyncStarintelDatabase, database: string, docs: seq[BookerPerson]): Future[seq[JsonNode]] {.async.} =
  var docids: seq[string]
  when defined(debug):
    echo %*docids
  for d in docs:
    docids.add(d.id)
  when defined(debug):
    echo "Bulk get from cache"
    echo $docids
  let rdocs = await star.server.bulkGet(database, %*docids)
  for rdoc in rdocs["results"].items:
      if rdoc["docs"]["error"].len != 0:
        echo($rdoc["ok"].fixDoc)



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
