import ../../src/starintel_doc/[documents, targets, relation]
import times
proc testBaseDocument() =
  let time = now().toTime.toUnix
  var doc = BookerDocument(dataset: "Tests",
                            dtype: "test_doc", date_added: time, date_updated: time, id: "test")
  doAssert doc.dataset == "Tests"
  doAssert doc.dtype == "test_doc"
  doAssert doc.date_added == time
  doAssert doc.date_updated == time
  doAssert doc.id == "test"



proc testBookerTarget() =
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
  var doc = newRelation(source=sourceId, target=targetId, relation = Relations.to, dataset = "test")
  assert doc.source == sourceId
  assert doc.target == targetId
  assert doc.relation == Relations.to


when isMainModule:
  echo "testing: BookerDocument"
  testBaseDocument()
  echo "testing: BookerTarget"
  testBookerTarget()
  echo "testing: BookerRelation"
  testRelation()
