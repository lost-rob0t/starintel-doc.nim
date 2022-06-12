import mycouch
import starintel_database
import cache
import ../spec/documents
import json
import asyncdispatch
import sequtils
import sugar
import tables
import options
import std/random
randomize()

type DeleteDoc = tuple
  id: string
  rev: string

const METADOC* = """{
  "_id": "_design/meta",
  "views": {
    "duplicated-docs": {
      "reduce": "function (keys, values, rereduce) {\n\n  if (rereduce) {\n    var res = [];\n    for (var i = 0; i < values.length; i++){\n      res = res.concat(values[i])\n    }\n    return res;\n  } else {\n    return values;\n  }\n}",
      "map": "function (doc) {\n  if(doc.type == \"org\"){\n      emit([doc.name], doc._id);\n}\n  if(doc.type == \"person\"){\n    emit([doc.fname + \"-\" + doc.mname + \"-\" + doc.lname + doc.pid], doc._id)\n  }\n}"
    }
  },
  "language": "javascript"
}"""

## This Is the Query to grab duplicate documents with the reduce function
proc createMetaView*(star: AsyncStarintelDatabase, ddoc: string) {.async.} =
  let x = await star.server.createOrUpdateDesignDoc(star.database, ddoc)
  when defined(debug):
    echo $x

proc getDups*(star: AsyncStarintelDatabase, view: string): Future[seq[JsonNode]] {.async.} =

  let DUPEQ = %*{"reduce": "true",
              "group": "true",
              "group_level": 4
              }

  var data: seq[JsonNode]
  let resp = await star.server.getView(star.database, "meta", view, DUPEQ)
  for row in resp["rows"].getElems:
    try:
      for id in row["value"]:
        data.add(%*{"id": id.getStr})
    except KeyError:
      # Couchdb Complaing that we are not using reduce the "correct" way
      discard

  result = data

