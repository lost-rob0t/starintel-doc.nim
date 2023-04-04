import ../../src/starintel_doc/documents
import std/[hashes, md5, sha1]


proc testUUID() =
  var doc = BookerDocument()
  doc.makeUUID
  doAssert doc.id.len == 36

proc testMD5ID() =
  var doc = BookerDocument()
  doc.makeMD5ID("foo")
  doAssert doc.id.len == 32
  doAssert doc.id == "acbd18db4cc2f85cedef654fccc4a4d8"

proc testSHAID() =
  var doc = BookerDocument()
  doc.makeSHAID("foo")
  doAssert doc.id.len == 40
  doAssert doc.id == "0BEEC7B5EA3F0FDBC95D0DD47F3C5BC275DA8A33"


when isMainModule:
  echo "Testing Document ID creation"
  echo "Tessting UUID"
  testUUID()
  echo "Tessting MD5"
  testMD5ID()
  echo "Tessting SHA1"
  testSHAID()
