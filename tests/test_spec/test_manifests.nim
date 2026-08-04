discard """
  action: run
"""

import std/json
import ../../src/starintel_doc/manifests

proc rejectsActor(node: JsonNode) =
  var rejected = false
  try:
    discard parseActorManifest(node)
  except ValueError:
    rejected = true
  doAssert rejected

let actorNode = parseJson("""
{
  "actorId": "actor.fec.import",
  "label": "FEC importer",
  "actorVersion": "1.0.0",
  "protocolVersion": "1",
  "specCompatibility": ["0.9.0"],
  "accepts": ["target"],
  "produces": ["person", "org", "relation"],
  "implementation": {
    "entrypoint": "fec_importer/main"
  }
}
""")
let actor = parseActorManifest(actorNode)
doAssert actor.actorId == "actor.fec.import"
doAssert actor.implementation.entrypoint == "fec_importer/main"
doAssert actor.dump["actorId"].getStr == "actor.fec.import"

var actorWithDocumentIds = actorNode.copy()
actorWithDocumentIds["documentIds"] = %*["starintel:person:1"]
rejectsActor(actorWithDocumentIds)

var actorWithLegacyDocumentIds = actorNode.copy()
actorWithLegacyDocumentIds["document_ids"] = %*["starintel:person:1"]
rejectsActor(actorWithLegacyDocumentIds)

var actorWithoutLocator = actorNode.copy()
actorWithoutLocator["implementation"] = newJObject()
rejectsActor(actorWithoutLocator)

let datasetNode = parseJson("""
{
  "datasetId": "dataset.fec",
  "name": "Federal Election Commission",
  "datasetVersion": "1.0.0",
  "specCompatibility": ["0.9.0"],
  "documentIds": ["starintel:person:1"],
  "documentTypes": ["person", "org", "relation"]
}
""")
let dataset = parseDatasetManifest(datasetNode)
doAssert dataset.datasetId == "dataset.fec"
doAssert dataset.documentIds == @["starintel:person:1"]
doAssert dataset.dump["documentIds"][0].getStr == "starintel:person:1"
