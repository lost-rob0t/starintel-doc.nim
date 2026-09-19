import std/json

type
  ManifestImplementation* = object
    inlineSource*: string
    entrypoint*: string
    package*: string
    uri*: string
    builtInId*: string
    serviceUrl*: string

  ActorManifest* = object
    actorId*: string
    label*: string
    description*: string
    actorVersion*: string
    protocolVersion*: string
    specCompatibility*: seq[string]
    roles*: seq[string]
    accepts*: seq[string]
    produces*: seq[string]
    inputPorts*: JsonNode
    outputPorts*: JsonNode
    routing*: JsonNode
    implementation*: ManifestImplementation
    runtime*: JsonNode
    dependencies*: JsonNode
    configuration*: JsonNode
    optionsSchema*: JsonNode
    capabilities*: seq[string]
    permissions*: seq[string]
    datasetRestrictions*: seq[string]
    resources*: JsonNode
    rateLimits*: JsonNode
    budgetLimits*: JsonNode
    mailboxPolicy*: JsonNode
    retryPolicy*: JsonNode
    deadLetterPolicy*: JsonNode
    restartPolicy*: JsonNode
    loopDetection*: JsonNode
    errorPolicy*: JsonNode
    healthChecks*: JsonNode
    readiness*: JsonNode
    shutdown*: JsonNode
    checkpointing*: JsonNode

  DatasetManifest* = object
    datasetId*: string
    name*: string
    description*: string
    datasetVersion*: string
    specCompatibility*: seq[string]
    documentIds*: seq[string]
    documentTypes*: seq[string]
    schemaRefs*: seq[string]
    predicateRegistryRef*: string
    storageBindings*: JsonNode
    storageLayers*: JsonNode
    indexes*: JsonNode
    materializations*: JsonNode
    embeddings*: JsonNode
    actorBindings*: JsonNode
    flowBindings*: JsonNode
    graphRefs*: seq[string]
    lineage*: JsonNode
    validationPolicy*: JsonNode
    statistics*: JsonNode
    accessControl*: JsonNode
    retentionPolicy*: JsonNode
    publication*: JsonNode
    migrationHistory*: JsonNode

const
  ActorManifestFields = [
    "actorId", "label", "description", "actorVersion", "protocolVersion",
    "specCompatibility", "roles", "accepts", "produces", "inputPorts",
    "outputPorts", "routing", "implementation", "runtime", "dependencies",
    "configuration", "optionsSchema", "capabilities", "permissions",
    "datasetRestrictions", "resources", "rateLimits", "budgetLimits",
    "mailboxPolicy", "retryPolicy", "deadLetterPolicy", "restartPolicy",
    "loopDetection", "errorPolicy", "healthChecks", "readiness", "shutdown",
    "checkpointing"
  ]
  DatasetManifestFields = [
    "datasetId", "name", "description", "datasetVersion",
    "specCompatibility", "documentIds", "documentTypes", "schemaRefs",
    "predicateRegistryRef", "storageBindings", "storageLayers", "indexes",
    "materializations", "embeddings", "actorBindings", "flowBindings",
    "graphRefs", "lineage", "validationPolicy", "statistics",
    "accessControl", "retentionPolicy", "publication", "migrationHistory"
  ]
  ImplementationFields = [
    "inlineSource", "entrypoint", "package", "uri", "builtInId", "serviceUrl"
  ]

proc contains(fields: openArray[string], key: string): bool =
  for field in fields:
    if field == key:
      return true

proc requireObject(node: JsonNode, path: string) =
  if node.kind != JObject:
    raise newException(ValueError, path & " must be an object")

proc rejectUnknownFields(
  node: JsonNode,
  allowed: openArray[string],
  path: string
) =
  requireObject(node, path)
  for key, _ in node.pairs:
    if not allowed.contains(key):
      raise newException(ValueError, path & " contains unknown field " & key)

proc requireString(node: JsonNode, key, path: string) =
  if not node.hasKey(key) or node[key].kind != JString or node[key].getStr.len == 0:
    raise newException(ValueError, path & "." & key & " must be a non-empty string")

proc requireStringArray(node: JsonNode, key, path: string) =
  if not node.hasKey(key) or node[key].kind != JArray:
    raise newException(ValueError, path & "." & key & " must be an array")
  for index in 0 ..< node[key].len:
    let item = node[key][index]
    if item.kind != JString or item.getStr.len == 0:
      raise newException(
        ValueError,
        path & "." & key & "[" & $index & "] must be a non-empty string"
      )

proc validateImplementation(node: JsonNode) =
  rejectUnknownFields(node, ImplementationFields, "$.implementation")
  var found = false
  for field in ImplementationFields:
    if node.hasKey(field):
      if node[field].kind != JString:
        raise newException(
          ValueError,
          "$.implementation." & field & " must be a string"
        )
      if node[field].getStr.len > 0:
        found = true
  if not found:
    raise newException(
      ValueError,
      "$.implementation requires an implementation locator"
    )

proc validateActorManifestJson*(node: JsonNode) =
  rejectUnknownFields(node, ActorManifestFields, "$")
  requireString(node, "actorId", "$")
  requireString(node, "label", "$")
  requireString(node, "actorVersion", "$")
  requireString(node, "protocolVersion", "$")
  requireStringArray(node, "specCompatibility", "$")
  requireStringArray(node, "accepts", "$")
  requireStringArray(node, "produces", "$")
  if not node.hasKey("implementation"):
    raise newException(ValueError, "$.implementation is required")
  validateImplementation(node["implementation"])

proc validateDatasetManifestJson*(node: JsonNode) =
  rejectUnknownFields(node, DatasetManifestFields, "$")
  requireString(node, "datasetId", "$")
  requireString(node, "name", "$")
  requireString(node, "datasetVersion", "$")
  requireStringArray(node, "specCompatibility", "$")

proc parseActorManifest*(node: JsonNode): ActorManifest =
  validateActorManifestJson(node)
  result = node.to(ActorManifest)

proc parseDatasetManifest*(node: JsonNode): DatasetManifest =
  validateDatasetManifestJson(node)
  result = node.to(DatasetManifest)

proc dump*(manifest: ActorManifest): JsonNode =
  %*manifest

proc dump*(manifest: DatasetManifest): JsonNode =
  %*manifest
