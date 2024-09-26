import ../../src/starintel_doc
import times
import json

proc testDomain() =
  let
    record = "www.google.com"
    recordType = "A"
    resolved = @["127.0.0.1"]
    doc = newDomain(record, recordType, resolved)
    doc2 = newDomain(record, recordType)

  assert len(doc.id) > 0
  assert len(doc.resolved) == 1
  assert doc.record == record
  assert doc2.record == record
  assert doc.recordType == recordType
  assert doc2.recordType == recordType
  assert doc.dtype == "Domain"

proc testService() =
  let
    port: int16 = 80
    name = "http"
    version = "1.1"
    doc = newService(port, name, version)
    doc2 = newService(port, name)

  assert doc.port == port
  assert doc.name == name
  assert doc.ver == version
  assert doc2.port == port
  assert doc2.name == name
  assert doc2.ver == ""
  assert doc.dtype == "Service"

proc testNetwork() =
  let
    asn = 15169
    org = "Google LLC"
    source = "whois"
    doc = newNetwork(asn, org, source)

  assert doc.asn == asn
  assert doc.org == org
  assert doc.dtype == "Network"

proc testHost() =
  let
    ip = "192.168.1.1"
    hostname = "example.local"
    source = "nmap"
    doc = newHost(ip, hostname, source)

  assert doc.ip == ip
  assert doc.hostname == hostname
  assert len(doc.id) > 0
  assert doc.dtype == "Host"

when isMainModule:
  echo "Testing: Domain"
  testDomain()
  echo "Testing: Service"
  testService()
  echo "Testing: Network"
  testNetwork()
  echo "Testing: Host"
  testHost()
