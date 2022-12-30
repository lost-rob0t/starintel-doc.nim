import options
import parsecsv
import json
import ../spec/spec
import strutils
import strformat
## Parse Json or csv data into spec complient json data.

type

  People* = object
    ## Configuration for json data holding data about people
    ## Fields are used to hold the name of the field
    fname*: string
    lname*: string
    mname*: string
    # if you only have a name field
    name*: string
    email*: string
    emailArray*: string
    address*: string
    street*: string
    street2*: string
    city*: string
    region*: string
    country*: string
    postal*: string
    orgName*: string
    orgType*: string
    orgArray*: string
    phone*: string # TODO
    phoneArray*: string # TODO
    bio*: string
    socialMediaArray*: string
    socialMedia*: string
    lat*: string
    long*: string
    dob*: string
    gender*: string
  Orgs* = object
    ## Configuration for json data holding organization data
    name*: string
    orgType*: string
    reg*: string


  Emails* =  object
    email*: string
    username*: string
    ## If you have the email username, domain and password
    emailUsername*: string
    emailDomain*: string
    emailPassword*: string

  Address* =  object
    ## Configuration for json data holding address data
    street*: string
    city*: string
    region*: string
    zip*: string
    street2*: string

  MetaData* =  object
    ## Not to Be confused with MetaConfig, this is the object holding metadata like dats and dataset info
    dateAdded*: string
    dateUpdated*: string
    dataset*: string
    defaultOrgType*: string
  MetaConfig* =  object
    ## Meta config holding all configrations for import jobs
    peopleJ*: People
    orgJ*: Orgs
    addressJ*: Address
    metadataJ*: MetaData

proc readConfig*(path: string): MetaConfig =
  ## Read a Json config that defines the mapping between fields
  var meta = MetaConfig()
  let f = open(path, fmRead)
  defer: f.close
  let jconfig = f.readAll.parseJson["jsonConfig"]
  meta.metadataJ = jconfig["meta"].to(MetaData)
  meta.peopleJ = jconfig["people"].to(People)
  meta.orgJ = jconfig["orgs"].to(Orgs)
  meta.addressJ = jconfig["address"].to(Address)
  result = meta



proc parsePerson*(config: MetaConfig, line: JsonNode): BookerPerson =
  var person = BookerPerson(dtype: "person", dataset: config.metadataJ.dataset)
  var orgs: seq[BookerOrg]
  person.fname = line{config.peopleJ.fname}.getStr("")
  person.lname = line{config.peopleJ.lname}.getStr("")
  person.mname = line{config.peopleJ.mname}.getStr("")
  person.bio = line{config.peopleJ.bio}.getStr("")
  if config.peopleJ.orgArray != "":
    for o in line[config.peopleJ.orgArray].getElems:
      var org = BookerOrg(dtype: "org", dataset: config.metadataJ.dataset, name: o.getStr(""))
      person.orgs.add(org)
  if config.peopleJ.orgName != "":
    #var org = BookerOrg(dtype: "org", dataset: config.metadataJ.dataset, source_dataset: config.metadataJ.source_dataset)
    var org = newOrg(line{config.peopleJ.orgName}.getStr(""),
                    line{config.peopleJ.orgType}.getStr(config.metadataJ.defaultOrgType))
    person.orgs.add(org)
  if config.peopleJ.email != "":
    let e = line{config.peopleJ.email}.getStr("")
    var email = e.newEmail
    person.emails.add(email)
  if config.peopleJ.emailArray != "":
    for e in line[config.peopleJ.emailArray].getElems:
      var email = newEmail(e.getStr)
      person.emails.add(email)
  if config.peopleJ.address != "false":
    let street = line{config.peopleJ.street}.getStr("")
    let street2 = line{config.peopleJ.street2}.getStr("")
    let city = line{config.peopleJ.city}.getStr("")
    let state = line{config.peopleJ.region}.getStr("")
    let country = line{config.peopleJ.country}.getStr("")
    let postal = line{config.peopleJ.postal}.getStr("")
    let lat = line{config.peopleJ.lat}.getFloat(0.0)
    let long = line{config.peopleJ.long}.getFloat(0.0)
    let address = newAddress(street, street2, city, postal, state, country, lat, long)
    person.address.add(address)
    person.region = city & ", " & country
  else:
    if line{config.peopleJ.region}.kind == JArray:
      for region in line{config.peopleJ.region}.getElems:
        person.region &= fmt"{region}, "
    person.region = line{config.peopleJ.region}.getStr("")
  person.dob = line{config.peopleJ.dob}.getStr("")
  person.gender = line{config.peopleJ.gender}.getStr("")
  result = person


proc parsePerson*(config: MetaConfig, parser: var CsvParser): BookerPerson =
  var person = BookerPerson(dtype: "person", dataset: config.metadataJ.dataset)
  person.fname = parser.rowEntry(config.peopleJ.fname)
  person.mname = parser.rowEntry(config.peopleJ.mname)
  person.lname = parser.rowEntry(config.peopleJ.lname)
  if config.peopleJ.bio != "":
    person.bio = parser.rowEntry(config.peopleJ.lname)
  if config.peopleJ.orgName != "":
    var org: BookerOrg
    try:
      org = newOrg(parser.rowEntry(config.peopleJ.orgName), parser.rowEntry(config.peopleJ.orgType))
    except KeyError:
      org = newOrg(parser.rowEntry(config.peopleJ.orgName), config.peopleJ.orgType)
    person.orgs.add(org)
  if config.peopleJ.email != "":
    let e = parser.rowEntry(config.peopleJ.email)
    var email = e.newEmail
    person.emails.add(email)
  if config.peopleJ.address != "false":
    var country: string
    let street = parser.rowEntry(config.peopleJ.street)
    var street2: string
    var lat, long: float64
    if config.peopleJ.street2 != "":
      street2 = parser.rowEntry(config.peopleJ.street2)
    let city = parser.rowEntry(config.peopleJ.city)
    let state = parser.rowEntry(config.peopleJ.region)
    try:
      country = parser.rowEntry(config.peopleJ.country)
    except KeyError:
      country = config.peopleJ.country
    let postal = parser.rowEntry(config.peopleJ.postal)
    if config.peopleJ.lat != "" or config.peopleJ.long != "":
        lat = parser.rowEntry(config.peopleJ.lat).parseFloat
        long = parser.rowEntry(config.peopleJ.long).parseFloat
    let address = newAddress(street, street2, city, postal, state, country, lat, long)
    person.address.add(address)
  else:
    person.region = parser.rowEntry(config.peopleJ.region)
  result = person
