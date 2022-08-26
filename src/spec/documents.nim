import std/[jsonutils, hashes, tables, json, options, sequtils, strutils]
import uuids
# TODO whendifed fast is using uuids, which is slow, flip them
var Joptions*: Joptions
Joptions.allowMissingKeys = true
Joptions.allowExtraKeys = true

type
    BookerDocument* = ref object of RootObj
      ## Base Object to hold the document metadata thats used to make a dcoument and store it in couchdb
      ## _id and _rev are renamed to id and rev due to limitations of nim.
      operation_id*: int
      id*: string
      source_dataset*: string
      dataset*: string
      dtype*: string
      date_added*: string
      date_updated*: string

    BookerPhone* = ref object of BookerDocument
      ## A Phone number
      phone*: string
      owner*: Option[string]
      carrier*: Option[string]
      status*: Option[string]
      phone_type*: Option[string]

    BookerMembership* = ref object of BookerDocument
      ## Document holding metadata linking two documents
      relation_type*: string
      title*: string
      roles*: seq[string]
      start_date*: string
      end_date*: string
      child*: string
      parent*: string


proc makeHash*(input: string): string =
  result = $hash(input)
  when defined(debug):
    echo $result


template link*[T,V](doc: T, field, data: V) =
  doc.field.add(data)


template makeUUID*[T](doc: T) =
  ## Generate a UUID for a document
  doc.id = $genUUID()

template makeEID*[T](doc: T, data: string) =
  ## Generate a EID
  ## for data include enough data to make it unique
  ## For example for a person; first name, middle name, last name can be used
  doc.eid = makeHash(data)
