import documents, entities
## Expiremental spec for defining hosts, domains, ports and services. For now split from web.nim

type
  BookerWeb* = ref object of BookerDocument
    # Extra fields to track the source
    source*: string

  BookerDomain* = ref object of BookerWeb
    recordType*: string
    domain*: string
    ip*: string

  BookerPort* = object
    port*: int16
    services*: seq[string]

  BookerASN* = object
    asn*: int32
    subnet*: string


  BookerNetwork* = object of BookerWeb
    org*: string
    asn*: BookerASN


  BookerHost* = ref object of BookerWeb
    hostname*: string
    ip*: string
    ports*: seq[BookerPort]
    os*: string

  BookerUrl* = ref object of BookerWeb
    url*: string
    content*: string


proc newDomain*(domain: string, recordType, ip: string = ""): BookerDomain =
  var doc = BookerDomain(recordType: recordType, domain: domain, ip: ip, dtype: "domain")
  doc.makeMD5ID(doc.domain & doc.ip & doc.recordType)
  result = doc

proc newPort*(port: int16): BookerPort =
  BookerPort(port: port)

proc newPort*(port: int16, services: seq[string]): BookerPort =
  BookerPort(port: port, services: services)

proc newASN*(asn: int32, subnet: string): BookerASN =
  BookerASN(asn: asn, subnet: subnet)

proc newNetwork*(asn: BookerASN, org: string): BookerNetwork =
  BookerNetwork(asn: asn, org: org, dtype: "network")


proc newHost*(ip, hostname: string = ""): BookerHost =
  var doc = BookerHost(hostname: hostname, ip: ip, dtype: "host")
  doc.makeMD5ID(doc.hostname & doc.ip)
  result = doc
proc newHost*(ip, hostname: string, network: BookerNetwork): BookerHost =
  var doc = BookerHost(hostname: hostname, ip: ip, network: network, dtype: "host")
  doc.makeMD5ID(doc.hostname & doc.ip)
  result = doc
