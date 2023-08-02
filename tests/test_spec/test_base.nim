import ../../src/starintel_doc/[documents, targets, relation]
import times
proc testBaseDocument() =
  let time = now().toTime.toUnix
  var doc = Document(dataset: "Tests",
                            dtype: "test_doc", date_added: time, date_updated: time, id: "test")
  doAssert doc.dataset == "Tests"
  doAssert doc.dtype == "test_doc"
  doAssert doc.date_added == time
  doAssert doc.date_updated == time
  doAssert doc.id == "test"



proc testTarget() =
  let target = "nsaspy"
  let dataset = "git accounts"
  let actor = "GitBot"
  var doc = newTarget(dataset, target, actor)
  assert doc.target == target
  assert doc.dataset == dataset
  assert doc.actor == actor
proc testRelation() =
  let sourceId = "testfoobar"
  let targetId = "testbarfoo"
  var doc = newRelation(source=sourceId, target=targetId, note = "Hello Graphs", dataset = "test")
  assert doc.source == sourceId
  assert doc.target == targetId
  assert doc.note == "Hello Graphs"

when isMainModule:
  echo "testing: Document"
  testBaseDocument()
  echo "testing: Target"
  testTarget()
  echo "testing: Relation"
  testRelation()
