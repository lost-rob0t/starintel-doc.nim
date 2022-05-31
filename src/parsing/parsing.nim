import json, sequtils
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


proc lineData*(line: JsonNode, config: MetaConfig): LineData =
  ## Parse a Json line and return LineData
  when defined(debug):
    echo $line
  # TODO work on a proc to fill instead of creating a new object (thats slow)
  # TODO Split this up
  var data = LineData()
  data.person = BookerPerson()

  if config.peopleJ.name != "":
    when defined(debug):
      echo config.peopleJ.name
    let ndata = line[config.peopleJ.name].getStr.split(" ")
    data.person.fname = some(ndata[0])
    if ndata.len > 1:
      data.person.mname = some(ndata[1])
      data.person.lname = some(ndata[2])
    else:
      data.person.lname = some(ndata[1])
  else:
    if config.peopleJ.fname != "":
      when defined(debug):
        echo config.peopleJ.fname
        echo line[config.peopleJ.fname].getStr

      var fname = line[config.peopleJ.fname].getStr
      if fname.len > 0:
        data.person.fname = some(fname)
    if config.peopleJ.mname != "":
      data.person.mname = some(line[config.peopleJ.mname].getStr)
    if config.peopleJ.lname != "":
      data.person.lname = some(line[config.peopleJ.lname].getStr)

  data.person.makeId

  if config.peopleJ.email.len != 0:
    let edata = line[config.peopleJ.email].getStr.split("@")
    var email = BookerEmail(email_username: edata[0], email_domain: edata[1], owner: some(data.person.id))
    email.makeId
    data.emails.add(email)


  if config.peopleJ.emailArray.len != 0:
    for email in line[config.peopleJ.emailArray].getElems:
      let edata = email.getStr.split("@")
      var e = BookerEmail(email_username: edata[0], email_domain: edata[1], owner: some(data.person.id))
      e.makeId
      data.emails.add(e)

  if config.peopleJ.phone.len != 0:
    var phone = BookerPhone(phone: line[config.peopleJ.phone].getStr, owner: some(data.person.id))
    phone.makeId
    data.phones.add(phone)

  if config.peopleJ.phoneArray.len != 0:
    for phone in line[config.peopleJ.phoneArray].getElems:
      var p = BookerPhone(phone: phone.getStr, owner: some(data.person.id))
      p.makeId
      data.phones.add(p)


  if config.peopleJ.orgName.len != 0:
    var org = BookerOrg(name: line[config.peopleJ.orgName].getStr)
    org.makeId
    data.orgs.add(org)

  if config.peopleJ.orgArray.len != 0:
    for org in line[config.peopleJ.orgArray].getElems:
      var o = BookerOrg(name: org.getStr)
      o.makeId
      data.orgs.add(o)

  result = data
