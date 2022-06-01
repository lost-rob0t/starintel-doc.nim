import json, sequtils, strutils
import ../spec/documents
import options
type
  BaseJson* = ref object of RootObj
    typef*: string
    memberships*: string
    dateAdded*: string
    dateUpdated*: string
    id*: string
    rev*: string
    dataset*: string
    sourceDataset*: string
    operationId*: string

  PeopleJson* = ref object of BaseJson
    ## Configuration for json data holding data about people
    ## Fields are used to hold the name of the json node
    nameOrder*: seq[string]
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
    orgName*: string
    orgType*: string
    orgArray*: string
    phone*: string
    phoneArray*: string
    roles*: string

  OrgJson* = ref object of BaseJson
    ## Configuration for json data holding organization data
    name*: string
    orgType*: string
    reg*: string


  EmailJson* = ref object of BaseJson
    email*: string
    username*: string

    ## If you have the email username, domain and password
    emailUsername*: string
    emailDomain*: string
    emailPassword*: string

  AddressJson* = ref object of BaseJson
    ## Configuration for json data holding address data
    street*: string
    city*: string
    region*: string
    zip*: string
    street2*: string

  MetaConfig* = ref object
    ## Meta config holding all configrations for import jobs
    peopleJ*: PeopleJson
    orgJ*: OrgJson
    addressJ*: AddressJson

  LineData* = ref object
    ## Holds the resulting booker docs after parsing a line
    person*: BookerPerson
    address*: BookerAddress
    emails*: seq[BookerEmail]
    phones*: seq[BookerPhone]
    orgs*: seq[BookerOrg]
    memberships*: seq[BookerMembership]


proc addMeta(node, config: JsonNode): JsonNode =
  var nnode = node
  let fields = config["meta"].getFields
  for key in config["meta"].keys:
    nnode{key}= config["meta"][key]
  result = nnode

proc readConfig*(path: string): MetaConfig =
  var meta = MetaConfig()
  let f = open(path, fmRead)
  defer: f.close
  let jconfig = f.readAll.parseJson["jsonConfig"]
  meta.peopleJ = jconfig["people"].addMeta(jconfig).to(PeopleJson)
  meta.orgJ = jconfig["orgs"].addMeta(jconfig).to(OrgJson)
  meta.addressJ = jconfig["address"].addMeta(jconfig).to(AddressJson)
  result = meta


proc parsePersonJ(line: JsonNode, config: MetaConfig): BookerPerson =
  ## Parse basic data about a person from a json line
  ## This DOES NOT GRAB EMAILS, OR PHONES
  var person = BookerPerson(`type`:"person")
  if config.peopleJ.name != "":
    when defined(debug):
      echo config.peopleJ.name
    let ndata = line[config.peopleJ.name].getStr.split(" ")
    person.fname = some(ndata[0])
    if ndata.len > 1:
      person.mname = some(ndata[1])
      person.lname = some(ndata[2])
    else:
      person.lname = some(ndata[1])
  else:
    if config.peopleJ.fname != "":
      when defined(debug):
        echo config.peopleJ.fname
        echo line[config.peopleJ.fname].getStr
      person.fname = some(line[config.peopleJ.fname].getStr)
    if config.peopleJ.mname != "":
      person.mname = some(line[config.peopleJ.mname].getStr)
    if config.peopleJ.lname != "":
      person.lname = some(line[config.peopleJ.lname].getStr)

  person.makeId
  result = person


proc parsePersonOrgJ(line: JsonNode, config: MetaConfig): seq[BookerOrg] =
  var data: seq[BookerOrg]
  if config.peopleJ.orgName.len != 0:
    var org = BookerOrg(name: line[config.peopleJ.orgName].getStr, `type`: "org")
    org.makeId
    data.add(org)
  if config.peopleJ.orgArray.len != 0:
    for org in line[config.peopleJ.orgArray].getElems:
      var o = BookerOrg(name: org.getStr, `type`: "org")
      o.makeId
      data.add(o)
      when defined(debug):
        echo o.name
  result = data
proc parsePersonPhoneJ(line: JsonNode, config: MetaConfig): seq[BookerPhone] =
  var data:  seq[BookerPhone]
  if config.peopleJ.phone.len != 0:
    var phone = BookerPhone(phone: line[config.peopleJ.phone].getStr, `type`: "phone")
    phone.makeId
    data.add(phone)

  if config.peopleJ.phoneArray.len != 0:
    for phone in line[config.peopleJ.phoneArray].getElems:
      var p = BookerPhone(phone: phone.getStr, `type`: "phone")
      p.makeId
      data.add(p)

  result = data
proc parsePersonEmailJ(line: JsonNode, config: MetaConfig): seq[BookerEmail] =
  var data: seq[BookerEmail]
  if config.peopleJ.email.len != 0:
    let edata = line[config.peopleJ.email].getStr.split("@")
    var email = BookerEmail(email_username: edata[0], email_domain: edata[1], `type`: "email")
    email.makeId
    data.add(email)
    when defined(debug):
      echo edata
  if config.peopleJ.emailArray.len != 0:
    for email in line[config.peopleJ.emailArray].getElems:
      let edata = email.getStr.split("@")
      var e = BookerEmail(email_username: edata[0], email_domain: edata[1], `type`: "email")
      e.makeId
      data.add(e)
      when defined(debug):
        echo edata
  result = data

proc parseOrgMetaJ*(line: JsonNode, data: var LineData, config: MetaConfig) =
  var org = BookerOrg(name: line[config.peopleJ.orgName].getStr, `type`: "org")
  org.makeId
  data.orgs.add(org)
proc parseRolesJ*(line: JsonNode, data: var LineData, config: MetaConfig) =
  for key in line[config.peopleJ.roles].keys:
    let d = line[config.peopleJ.roles][key]
    var org = BookerOrg(name: key, `type`: "org")
    org.makeID
    var membership = BookerMembership(title: d["title"].getStr, child: data.person.id, parent: org.id,
                                      `type`: "membership")
    membership.makeId
    org.memberships.add(membership.id)
    data.person.memberships.add(membership.id)
    data.orgs.add(org)
    data.memberships.add(membership)
proc makeRelations*(data: var LineData, line: JsonNode, config: MetaConfig) =
  for email in data.emails:
    email.owner = some(data.person.id)
    data.person.emails.add(email.id)
  for phone in data.phones:
    phone.owner = some(data.person.id)
    data.person.phones.add(phone.id)

proc parseJsonPerson*(line: JsonNode, config: MetaConfig): LineData =
  ## Parse a Json line and return LineData about a person
  when defined(debug):
    echo $line
  # TODO work on a proc to fill instead of creating a new object (thats slow)
  var data = LineData()
  data.person = line.parsePersonJ(config)
  data.emails = line.parsePersonEmailJ(config)
  if config.peopleJ.orgName.len != 0:
    line.parseOrgMetaJ(data, config)
  if config.peopleJ.roles.len != 0:
    line.parseRolesJ(data, config)
  data.phones = line.parsePersonPhoneJ(config)
  data.makeRelations(line, config)
  when defined(debug):
    echo "Emails: " & $data.emails.len
    echo "Orgs" & $data.orgs.len
    echo "Memberships" & $data.memberships.len
  result = data
