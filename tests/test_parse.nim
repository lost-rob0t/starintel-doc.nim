import ../src/utils/doc_parsing
import ../src/utils/benchmark
import ../src/starintel_doc
import json, jsony
import parsecsv
import strutils
proc testBasic() =
  var meta = readConfig("config.json")
  let f = open("test.json", fmRead)
  for line in f.lines:
    discard meta.parsePerson(line.parseJson)
proc testAdress() =
  var meta = readConfig("config-address.json")
  let f = open("test-address.json", fmRead)
  for line in f.lines:
    discard meta.parsePerson(line.parseJson)
proc testJsony() =
  var meta = readConfig("config-address.json")
  let f = open("test-address.json", fmRead)
  for line in f.lines:
    discard meta.parsePerson(line.fromJson)



proc testCsv() =
  var meta = readConfig("config-csv.json")
  var p: CsvParser
  p.open("test.csv")
  p.readHeaderRow
  while p.readRow():
    discard meta.parsePerson(p)
  p.close

benchmark "Basic eample test":
  testBasic()
benchmark "Full json":
  testAdress()
benchmark "Jsony Test":
  testJsony()
benchmark "Csv":
  testCsv()
