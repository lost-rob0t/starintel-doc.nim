import documents, locations, web, phones

type
  BookerEntity* = ref object of BookerDocument
    ## A base object that represents a entity
    ## Type of entity such as group, NGO, person, software, ect.
    etype*: string

    ## Entity uuid that is globaly unique
    eid*: string


  BookerOrg* = ref object of BookerEntity
    reg*: string
    country*: string
    name*: string
    officers*: seq[BookerPerson]
    website*: string
    bio*: string
  BookerPerson* = ref object of BookerEntity
    ## A object that represents a person in starintel
    ## NOTE: person is merged with member and member is no longer used
    fname*: string
    mname*: string
    lname*: string
    bio*: string
    dob*: string
    social_media*: seq[BookerUsername]
    phones*: seq[BookerPhone]
    emails*: seq[BookerEmail]
    address*: seq[BookerAddress]
    orgs*: seq[BookerOrg]
    gender*: string
    region*: string
    misc*: seq[string]
proc renameHook*(v: var BookerPerson, fieldName: var string) =
  if fieldName == "rev":
    fieldName = "_rev"
  if fieldName == "id":
    fieldName = "_id"
proc renameHook*(v: var BookerOrg, fieldName: var string) =
  if fieldName == "rev":
    fieldName = "_rev"
  if fieldName == "id":
    fieldName = "_id"



proc newOrg*(name, etype: string): BookerOrg =
  var o = BookerOrg(name: name, etype: etype, reg: "", country: "", website: "")
  o.makeEID(name)
  o.makeUUID()
  result = o

# TODO add procs for adding board members/officers

proc clear*(doc: var BookerPerson) =
  doc.emails = @[]
  doc.phones = @[]
  doc.social_media = @[]
  doc.address = @[]
  doc.orgs = @[]
