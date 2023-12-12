import ../../src/starintel_doc
import times
import json


proc testScopeCreation() =
  var scope = newScope("StarIntel", "StarIntel is a framwork for the collection of intelligence data.")
  scope.inScopeAdd("github.com")
  scope.outScopeAdd("testgithub.com")
  doAssert scope.dataset == "StarIntel"
  doAssert scope.description == "StarIntel is a framwork for the collection of intelligence data."
  doAssert scope.outscope[0] == "testgithub.com"
  doAssert scope.inscope[0] == "github.com"


proc testInscope() =
  var scope = newScope("StarIntel", "StarIntel is a framwork for the collection of intelligence data.")
  scope.inScopeAdd("github.com")
  scope.outScopeAdd("testgithub.com")


proc testHackerOneScope() =
  var scope = newScope("HackerOne", "HackerOne is a platform for bug bounty programs.")
  scope.inScopeAdd(".*.hackerone.com")
  scope.inscopeAdd("api.hackerone.com")
  scope.outScopeAdd("testhackerone.com")
  doAssert scope.contains("foo.hackerone.com") == true
  doAssert scope.contains("testhackerone.com") == false
when isMainModule:
  echo "testing: Scope Creation"
  testScopeCreation()
  echo "testing: Scope tests"
  testHackerOneScope()
