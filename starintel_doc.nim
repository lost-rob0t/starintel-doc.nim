import strutils, sequtils
import json, options
import std/jsonutils

var Joptions*: Joptions
Joptions.allowMissingKeys = true
Joptions.allowExtraKeys = true

type
    BookerDocument* = ref object of RootObj
      ## Base Object to hold the document metadata thats used to make a dcoument and store it in couchdb
      ## _id and _rev are renamed to id and rev due to limitations of nim.
      operation_id*: int
      id*: string
      rev*: Option[string]
      owner_id*: Option[int]
      source_dataset*: string
      dataset*: string
      `type`*: string
      memberships*: seq[string]
      date_added*: string
      date_updated*: string

    BookerPerson* = ref object of BookerDocument
      ## A object that represents a person in starintel
      ## NOTE: person is merged with member and member is no longer used
      fname*: Option[string]
      mname*: Option[string]
      lname*: Option[string]
      bio*: Option[string]
      dob*: Option[string]
      age*: Option[int]
      social_media*: seq[string]
      phones*: seq[string]
      emails*: seq[string]
      locations*: 
      ip*: seq[string]
      orgs*: seq[string]
      education*: seq[string]
      comments*: seq[string]
      gender*: Option[string]
      political_party*: Option[string]

    BookerOrg* = ref object of BookerDocument
      ## An object that represents a compnay or organization 

      ## Name Of org
      name*: string
      bio*: Option[string]
      country*: Option[string]
      reg_number*: Option[string]
      address*: seq[string]
      email_formats*: seq[string]
      organization_type*: Option[string]

    BookerAddress* = ref object of BookerDocument
      ## An address. Do not use to represent a reigon!
      ## may only work for us postal system
      ## Members is a seq of document id that point to other people or org docs.
      street*: Option[string]
      city*: Option[string]
      state*: Option[string]
      zip*: Option[string]
      apt*: Option[string]

    BookerEmail* = ref object of BookerDocument
      ## A email address
      ## Owner and Password is Optional
      ## data_breach is used to track what breaches the email is part of
      email_username*: string
      email_domain*: string
      email_password*: Option[string]
      data_breach*: seq[string]
      owner*: Option[string]
      username*: Option[string]


    BookerPhone* = ref object of BookerDocument
      ## A Phone number
      phone*: string
      owner*: Option[string]
      carrier*: Option[string]
      status*: Option[string]
      phone_type*: Option[string]

    BookerUser* = ref object of BookerDocument
      ## A object that represents a user
      url*: Option[string] # Url to the users page
      username*: string
      domain*: string
      phones*: seq[string]
      emails*: seq[string]
      orgs*: seq[string]

    BookerMessage* = ref object of BookerDocument
      ## a object representing a instant message
      ## Use Booker EmailMessage For Email Content
      ## BookerSocialMPost for social media post
      message*: string
      platform*: string
      username*: string
      is_reply*: bool
      mesage_id*: Option[string]
      reply_to*: Option[string]
      group*: string # if none assume dm chat
      channel*: Option[string] # for discord

    BookerEmailMessage* = ref object of BookerDocument
      ## a object represented as a email message
      body*: string
      subject*: Option[string]
      to*: string
      `from`*: string
      headers*: Option[string]
      cc*: seq[string]
      bcc*: seq[string]

    BookerMembership* = ref object of BookerDocument
      ## Document holding metadata linking two documents
      title*: string
      roles*: seq[string]
      start_date*: string
      end_date*: string
      child*: string
      parent*: string

    BookerBreach* = ref object of BookerDocument
      total*: int
      description*: string
      url*: string

    BookerWebService* = ref object of BookerDocument
      port*: int
      service_name*: string
      source*: string
      owner*: string
      host*: string
      service_name*: string
      service_version*: string

    BookerHost* = ref object of BookerDocument
      ip*: string
      hostname*: string
      operating_system*: string
      asn*: int
      country*: string
      network_name*: string
      owner*: string
      vulns*: seq[string]
      services*: seq[string]

    BookerCVE* = ref object of BookerDocument
      cve_number*: string
      score*: int









func flatten_doc*(json_id: JsonNode): JsonNode =
  ## TODO Remove this becuase its not needed anymore
  ## Flatten a doc so it can be marshalled into a object

  let metadata = json_id{"metadata"}
  var data = metadata
  data["operation_id"] = json_id{"operation_id"}
  data["source_dataset"] = json_id{"source_dataset"}
  data["dataset"] = json_id{"dataset"}
  data["date_added"] = json_id{"date_added"}
  data["date_updated"] = json_id{"date_updated"}
  data["owner_id"] = json_id{"owner_id"}
  data["id"] = json_id{"_id"}
  data["rev"] = json_id{"_rev"}
  data["type"] = json_id{"type"}
  return data


