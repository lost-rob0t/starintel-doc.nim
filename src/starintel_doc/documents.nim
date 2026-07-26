import std/[hashes, md5, sha1, strutils]
import ulid
from times import getTime, toUnix
export getTime, toUnix
import json
import typetraits

const
    DOC_VERSION* = "0.9.0"
    LEGACY_DOC_VERSION* = "0.7.3"

type
    Document* = ref object of RootObj
        ## Legacy flat 0.7.x compatibility object.
        ## New code should use starintel_doc/v090 for strict v0.9.0 documents.
        id*: string
        dataset*: string
        dtype*: string
        date_added*: int64
        date_updated*: int64
        version*: string = LEGACY_DOC_VERSION
        sources*: seq[string]

template link*[T, V](doc: T, field: untyped, data: V) =
    field.add(data)


template makeUUID*[T](doc: T) =
    ## Generate a UUID for a document
    doc.id = ulid()


# TODO setId
# overload for each type

template makeMD5ID*[T](doc: T, data: string) =
    ## Generate a MD5 checksum for the document id
    doc.id = $toMD5(data)


template makeSHAID*[T](doc: T, data: string) =
    ## Generate a SHA1 checksum for the document ID
    doc.id = $secureHash(data)


template timestamp*[T](doc: T) =
    ## Add a timestamp to the document
    ## Not done in helpers because sometimes you want the time from the data source
    let t = getTime()
    doc.date_added = t.toUnix()
    doc.date_updated = t.toUnix()


template updateTime*[T](doc: T) =
    ## Update the date_updated timestamp on the document
    let t = getTime()
    doc.date_updated = t.toUnix()


template setType*[T](doc: T) =
    doc.dtype = toLowerAscii($typeOf(doc))


template setMeta*[T](doc: T, docDataset: string = "star-intel") =
    ## Add metadata to the legacy document.
    let t = getTime()
    doc.setType
    if doc.date_added == 0:
        doc.date_added = t.toUnix()
    if doc.date_updated == 0:
        doc.date_updated = t.toUnix()
    if doc.id.len == 0:
        doc.makeUUID
    if doc.dataset.len == 0:
        doc.dataset = docDataset


proc addSource*[T](doc: T, tag: string) =
    doc.sources.add(tag)


proc dump*[T](doc: T): JsonNode =
    ## Dump a legacy document to JSON, renaming id to CouchDB _id.
    var jdoc = %*doc
    jdoc{"_id"} = newJString(doc.id)
    jdoc.delete("id")
    result = jdoc


proc load*[T](node: JsonNode, t: typedesc[T]): T =
    ## Load a legacy document from JSON, accepting optional CouchDB _rev.
    var jdoc = node.copy()
    jdoc{"id"} = jdoc["_id"]
    if jdoc.hasKey("_rev"):
        jdoc{"rev"} = jdoc["_rev"]
    result = jdoc.to(t)


when isMainModule:
    var doc = Document()
    doc.setType()
    echo doc.dump
