when not defined(js):
  import std/[hashes, md5, sha1]
  import ulid
from times import getTime, toUnix
export getTime, toUnix
import json
import typetraits

type
    Document* = ref object of RootObj
        ## Base Object to hold the document metadata thats used to make a dcoument and store it in couchdb
        id*: string
        dataset*: string
        dtype*: string
        date_added*: int64
        date_updated*: int64


# proc makeHash*(input: string): string =
#     result = $hash(input)
#     when defined(debug):
#         echo $result


template link*[T, V](doc: T, field: untyped, data: V) =
    field.add(data)



template makeUUID*[T](doc: T) =
    ## Generate a UUID for a document
    doc.id = ulid()

# TODO remove this
# template makeEID*[T](doc: T, data: string) =
#     ## Generate a EID
#     ## for data include enough data to make it unique
#     ## For example for a person; first name, middle name, last name can be used
#     doc.eid = makeHash(data)



template makeMD5ID*[T](doc: T, data: string) =
    ## Generate a MD5 checksum for the document id
    doc.id = $toMD5(data)


template makeSHAID*[T](doc: T, data: string) =
    ## Generate a SHA1 checksume for the document ID
    doc.id = $secureHash(data)


template timestamp*[T](doc: T) =
    ## Add a timestamp to the document
    ## Not done in helpers because sometimes you want the time from the data source
    let t = getTime()
    doc.date_added = t.toUnix()
    doc.date_updated = t.toUnix()


template updateTime*[T](doc: T) =
    ## update the date_updated timestamp to the document
    let t = getTime()
    doc.date_updated = t.toUnix()


template setType*[T](doc: T) = doc.dtype = $typeOf(doc)

template addMetadata*[T](doc: T, dataset: string = "star-intel") =
  ## Add Metadata to the document
  ## if a field is set, it will not set it.
  ## If the dataset is missing, it will set default from `dataset` argument.
  let t = getTime()
  if doc.date_added = 0:
      doc.date_added = t.toUnix()
  if doc.date_updated = 0:
      doc.date_updated = t.toUnix()
  if doc.id.len == 0:
    doc.makeUUID
  if doc.dataset.len == 0:
    doc.dataset = dataset
  doc.setType

proc dump*[T](doc: T): JsonNode =
    var jdoc = %*doc
    jdoc{"_id"} = newJString(doc.id)
    jdoc.delete("id")
    result = jdoc


proc load*[T](node: JsonNode, t: typedesc[T]): T =
    var jdoc = node
    jdoc{"id"} = jdoc["_id"]
    jdoc{"rev"} = jdoc["_rev"]
    result = jdoc.to(t)


template setMeta*[T](doc: T, dataset: string) =
    doc.dataset = dataset
    doc.timestamp
    doc.setType


when isMainModule:
    var doc = Document()
    doc.setType()
    echo doc.dump
