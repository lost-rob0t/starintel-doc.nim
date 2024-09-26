import documents, entities, tables
## Expiremental spec for defining hosts, domains, ports and services. For now split from web.nim

type
  Domain* = ref object of Document
    recordType*: string
    record*: string
    resolved*: seq[string]

  Service* = ref object of Document
    port*: int16
    name*: string
    ver*: string


  Network* = object of Document
    org*: string
    asn*: int
    subnet*: string


  Host* = ref object of Document
    hostname*: string
    ip*: string
    os*: string


  Url* = ref object of Document
    url*: string
    path*: string
    query*: string
    content*: string


proc newDomain*(domain, recordType: string): Domain =
  result = Domain(recordType: recordType, record: domain)
  result.makeMD5ID(result.record & result.recordType)
  result.setType

proc newDomain*(domain, recordType: string, resolved: seq[string]): Domain =
  result = Domain(recordType: recordType, record: domain, resolved: resolved)
  result.makeMD5ID(result.record & result.recordType)
  result.setType



proc newService*(port: int16, name: string): Service =
  Service(port: port, name: name)

proc newService*(port: int16, name: string, version: string): Service =
  result = Service(port: port, name: name, ver: version)
  result.setType

proc newNetwork*(asn: int, org, source: string): Network =
  result = Network(asn: asn, org: org)
  result.setType


proc newHost*(ip, hostname, source: string): Host =
  result = Host(hostname: hostname, ip: ip)
  result.makeMD5ID(result.ip)
  result.setType
