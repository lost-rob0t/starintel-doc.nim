import std/[hashes, md5, sha1]
import uuids
import times
import json
type
    BookerDocument* = ref object of RootObj
      ## Base Object to hold the document metadata thats used to make a dcoument and store it in couchdb
      id*: string
      rev*: string
      dataset*: string
      dtype*: string
      date_added*: int64
      date_updated*: int64


proc makeHash*(input: string): string =
  result = $hash(input)
  when defined(debug):
    echo $result

template link*[T,V](doc: T, field: untyped, data: V) =
  field.add(data)


template makeUUID*[T](doc: T) =
  ## Generate a UUID for a document
  doc.id = $genUUID()

template makeEID*[T](doc: T, data: string) =
  ## Generate a EID
  ## for data include enough data to make it unique
  ## For example for a person; first name, middle name, last name can be used
  doc.eid = makeHash(data)


template makeMD5ID*[T](doc: T, data: string) =
  ## Generate a MD5 checksum for the document id
  doc.id = $toMD5(data)

template makeSHAID*[T](doc: T, data: string) =
  ## Generate a SHA1 checksume for the document ID
  doc.id = $secureHash(data)

proc dump*[T](doc: T): JsonNode =
  var jdoc = %*doc
  jdoc{"_id"} = newJString(doc.id)
  jdoc.delete("id")
  if doc.rev.len != 0:
    jdoc{"_rev"} = newJString(doc.rev)
    jdoc.delete("rev")
  result = jdoc

proc load*[T](doc: JsonNode): T =
  var jdoc = doc
  jdoc{"id"} = jdoc["_id"]
  jdoc{"rev"} = jdoc["_rev"]
  result = jdoc.to(T)
