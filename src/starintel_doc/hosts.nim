import documents, entities, tables
## Expiremental spec for defining hosts, domains, ports and services. For now split from web.nim

type
  Domain* = ref object of Document
    recordType*: string
    record*: string
    ips*: seq[string]

  Port* = object
    number*: int16
    services*: seq[string]

  ASN* = object
    number*: int32
    subnet*: string


  Network* = object of Document
    org*: string
    asn*: ASN


  Host* = ref object of Document
    hostname*: string
    ip*: string
    ports*: seq[Port]
    os*: string


  Url* = ref object of Document
    url*: string
    statusCode*: int
    headers*: Table[string, string]
    content*: string

  Finding* = ref object of Document
    data*: string


proc newDomain*(domain, recordType: string): Domain =
  var doc = Domain(recordType: recordType, record: domain, dtype: "Domain")
  doc.makeMD5ID(doc.record & doc.recordType)
  result = doc

proc newPort*(port: int16): Port =
  Port(number: port)

proc newPort*(port: int16, services: seq[string]): Port =
  Port(number: port, services: services)

proc newASN*(asn: int32, subnet: string): ASN =
  ASN(number: asn, subnet: subnet)

proc newNetwork*(asn: ASN, org, source: string): Network =
  Network(asn: asn, org: org, dtype: "network")


proc newHost*(ip, hostname, source: string): Host =
  var doc = Host(hostname: hostname, ip: ip, dtype: "host")
  doc.makeMD5ID(doc.hostname & doc.ip)
  result = doc
