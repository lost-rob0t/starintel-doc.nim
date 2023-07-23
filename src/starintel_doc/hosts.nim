import documents, entities
## Expiremental spec for defining hosts, domains, ports and services. For now split from web.nim

type
  Web* = ref object of Document
    # Extra fields to track the source
    source*: string

  Domain* = ref object of Web
    recordType*: string
    domain*: string
    ip*: string

  Port* = object
    port*: int16
    services*: seq[string]

  ASN* = object
    asn*: int32
    subnet*: string


  Network* = object of Web
    org*: string
    asn*: ASN


  Host* = ref object of Web
    hostname*: string
    ip*: string
    ports*: seq[Port]
    os*: string

  Url* = ref object of Web
    url*: string
    content*: string


proc newDomain*(domain: string, recordType, ip: string = ""): Domain =
  var doc = Domain(recordType: recordType, domain: domain, ip: ip, dtype: "domain")
  doc.makeMD5ID(doc.domain & doc.ip & doc.recordType)
  result = doc

proc newPort*(port: int16): Port =
  Port(port: port)

proc newPort*(port: int16, services: seq[string]): Port =
  Port(port: port, services: services)

proc newASN*(asn: int32, subnet: string): ASN =
  ASN(asn: asn, subnet: subnet)

proc newNetwork*(asn: ASN, org: string): Network =
  Network(asn: asn, org: org, dtype: "network")


proc newHost*(ip, hostname: string = ""): Host =
  var doc = Host(hostname: hostname, ip: ip, dtype: "host")
  doc.makeMD5ID(doc.hostname & doc.ip)
  result = doc
