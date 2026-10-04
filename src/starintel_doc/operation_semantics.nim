## Native enforcement of the source-locked core.star operation invariants.
## Called only after concrete generated structural validation succeeds.
import std/[json, sets, tables, strutils]
proc items(node: JsonNode, key: string): JsonNode =
  if node.hasKey(key): node[key] else: newJArray()
proc unique(items: JsonNode, key: string): HashSet[string] =
  for item in items:
    let value = item[key].getStr.strip
    if value.len == 0 or value in result:
      raise newException(ValueError, key & ": empty or duplicate identifier")
    result.incl(value)
proc refs(values: JsonNode, known: HashSet[string]) =
  for value in values:
    if value.getStr notin known:
      raise newException(ValueError, "unknown operation reference: " & value.getStr)
proc validateOperationSemantics*(document: JsonNode) =
  if document["dtype"].getStr != "operation": return
  if document["mission"].getStr.strip.len == 0:
    raise newException(ValueError, "non-empty mission required")
  let phases = items(document, "phases")
  if phases.len == 0: raise newException(ValueError, "at least one phase required")
  let phaseIds = unique(phases, "phaseId")
  let datasets = items(document, "datasets")
  let datasetIds = unique(datasets, "bindingId")
  let capabilities = items(document, "capabilityGaps")
  let capabilityIds = unique(capabilities, "capabilityId")
  let assignments = items(document, "assignments")
  let actions = items(document, "postActions")
  discard unique(assignments, "assignmentId")
  discard unique(actions, "actionId")
  var dependencies = initTable[string, HashSet[string]]()
  var excluded = initHashSet[string]()
  for value in items(document, "outOfScope"): excluded.incl(value.getStr)
  for phase in phases:
    let id = phase["phaseId"].getStr.strip
    refs(items(phase, "dependsOn"), phaseIds)
    var pending = initHashSet[string]()
    for value in items(phase, "dependsOn"): pending.incl(value.getStr)
    dependencies[id] = pending
    if phase["objective"].getStr.strip.len == 0:
      raise newException(ValueError, "phase objective required")
    refs(items(phase, "datasetBindingIds"), datasetIds)
    refs(items(phase, "requiredCapabilityIds"), capabilityIds)
    for value in items(phase, "inScope"):
      if value.getStr in excluded: raise newException(ValueError, "outOfScope overrides phase inScope")
    if phase.getOrDefault("state").getStr == "completed" and items(phase, "completionEvidence").len == 0:
      raise newException(ValueError, "completed phase requires evidence")
    if document.getOrDefault("status").getStr == "completed" and phase.getOrDefault("state").getStr notin ["completed", "skipped"]:
      raise newException(ValueError, "completed operation has nonterminal phase")
  # Iterative topological elimination bounds stack depth on untrusted inputs.
  while dependencies.len > 0:
    var ready: seq[string]
    for id, pending in dependencies:
      if pending.len == 0: ready.add(id)
    if ready.len == 0: raise newException(ValueError, "phase dependency cycle")
    for id in ready: dependencies.del(id)
    for id, pending in dependencies.mpairs:
      for done in ready: pending.excl(done)
  for binding in datasets: refs(items(binding, "phases"), phaseIds)
  for capability in capabilities: refs(items(capability, "requiredBy"), phaseIds)
  for assignment in assignments: refs(items(assignment, "phaseIds"), phaseIds)
  for action in actions: refs(items(action, "datasetBindingIds"), datasetIds)

proc validateWorkflowSemantics*(document: JsonNode) =
  if document["dtype"].getStr == "dataset-manifest":
    var keys = initHashSet[string]()
    for item in items(document, "countsByDtype"):
      let key = item["key"].getStr
      if key in keys: raise newException(ValueError, "countsByDtype: duplicate original map key")
      keys.incl(key)
