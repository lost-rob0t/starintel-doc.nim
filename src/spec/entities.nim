import std/[options, ]
import documents, locations, web, phones

type
  BookerEntity* = ref object of BookerDocument
    ## A base object that represents a entity
    ## Type of entity such as group, NGO, person, software, ect.
    etype: string

    ## Entity uuid that is globaly unique
    eid: string


  BookerOrg* = ref object of BookerEntity
    reg*: Option[string]
    country*: Option[string]
    name*: string
    founders*: seq[BookerPerson]
    emailFormat*: Option[string]
    officers*: seq[BookerPerson]
    website*: Option[string]
    boardMembers*: seq[BookerPerson]
    address*: seq[BookerAddress]

  BookerPerson* = ref object of BookerEntity
    ## A object that represents a person in starintel
    ## NOTE: person is merged with member and member is no longer used
    fname*: Option[string]
    mname*: Option[string]
    lname*: Option[string]
    bio*: Option[string]
    dob*: Option[string]
    age*: Option[int]
    social_media*:  seq[string]
    phones*: seq[BookerPhone]
    emails*: seq[BookerEmail]
    address*: seq[BookerAddress]
    ip*: seq[string]
    orgs*: seq[BookerOrg]
    education*: seq[string]
    gender*: Option[string]
    political_party*: Option[string]
    interests*: seq[string]
    memberships*: seq[string]
