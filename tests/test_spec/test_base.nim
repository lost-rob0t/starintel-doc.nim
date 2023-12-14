import ../../src/starintel_doc/[documents, targets, relation, scope]
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

proc testScan() =
  let target = "nsaspy"
  let dataset = "git accounts"
  let actor = "GitBot"
  var scope = newScope("HackerOne", "HackerOne is a platform for bug bounty programs.")
  scope.inScopeAdd(".*.hackerone.com")
  scope.inscopeAdd("api.hackerone.com")
  scope.outScopeAdd("testhackerone.com")
  var scan = newScan(dataset, target, actor, scope)
  assert scan.target.target == target
  assert scan.target.dataset == dataset
  assert scan.target.actor == actor
  assert scan.scope.dataset == "HackerOne"



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
  echo "testing: ScanInput"
  testScan()
  echo "testing: Relation"
  testRelation()
