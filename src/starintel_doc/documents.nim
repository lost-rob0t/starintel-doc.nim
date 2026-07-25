import std/[hashes, json, md5, sha1, strutils, times, typetraits]
import ulid
import schema_org

export getTime, toUnix
export schema_org

const DOC_VERSION* = "0.9.0"

type
  Document* = ref object of RootObj
    ## Canonical StarIntel v0.9 envelope. Subtype fields are nested under data by dump().
    id*: string
    rev*: string
    dataset*: string
    dtype*: string
    schema_version*: string = DOC_VERSION
    version*: int = 1
    date_added*: string
    date_updated*: string
    title*: string
    summary*: string
    description*: string
    status*: string
    language*: string
    tags*: seq[string]
    labels*: seq[string]
    aliases*: seq[string]
    keywords*: seq[string]
    identifiers*: seq[JsonNode]
    sources*: seq[string]
    evidence*: seq[JsonNode]
    temporal*: JsonNode
    provenance*: JsonNode
    assessment*: JsonNode
    verification*: JsonNode
    handling*: JsonNode
    lineage*: JsonNode
    quality*: JsonNode
    workflow*: JsonNode
    geospatial*: JsonNode
    attachments*: seq[JsonNode]
    related_ids*: seq[string]
    notes*: seq[string]
    schema_org*: JsonNode
    data*: JsonNode
    extensions*: JsonNode

template link*[T, V](doc: T, field: untyped, value: V) =
  field.add(value)

proc utcNow*(): string =
  now().utc.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'")

proc ensureObject(node: var JsonNode) =
  if node.isNil or node.kind != JObject:
    node = newJObject()

template makeUUID*[T](doc: T) =
  doc.id = ulid()

# Compatibility helpers retained for existing callers.
template makeMD5ID*[T](doc: T, value: string) =
  doc.id = $toMD5(value)

template makeSHAID*[T](doc: T, value: string) =
  doc.id = $secureHash(value)

template timestamp*[T](doc: T) =
  let stamp = utcNow()
  doc.date_added = stamp
  doc.date_updated = stamp

template updateTime*[T](doc: T) =
  doc.date_updated = utcNow()
  doc.version = max(1, doc.version) + 1

template setType*[T](doc: T) =
  var typeName = $typeOf(doc)
  if typeName.startsWith("ref "):
    typeName = typeName[4 .. ^1]
  doc.dtype = canonicalDtype(typeName)

proc ensureSchemaOrg*[T](doc: T) =
  let defaults = schemaOrgMetadata(doc.dtype, doc.id)
  if doc.schema_org.isNil or doc.schema_org.kind != JObject:
    doc.schema_org = defaults
  else:
    for key, value in defaults.pairs:
      if key == "@id" or not doc.schema_org.hasKey(key):
        doc.schema_org[key] = value

template setMeta*[T](doc: T, docDataset: string = "star-intel") =
  doc.setType
  if doc.date_added.len == 0 or doc.date_updated.len == 0:
    doc.timestamp
  if doc.id.len == 0:
    doc.makeUUID
  if doc.dataset.len == 0:
    doc.dataset = docDataset
  doc.schema_version = DOC_VERSION
  if doc.version < 1:
    doc.version = 1
  if doc.status.len == 0:
    doc.status = "recorded"
  if doc.language.len == 0:
    doc.language = "en"
  ensureObject(doc.temporal)
  ensureObject(doc.provenance)
  ensureObject(doc.assessment)
  ensureObject(doc.verification)
  if not doc.verification.hasKey("status"):
    doc.verification["status"] = %"unverified"
  if not doc.verification.hasKey("verified"):
    doc.verification["verified"] = %false
  ensureObject(doc.handling)
  if not doc.handling.hasKey("visibility"):
    doc.handling["visibility"] = %"public"
  if not doc.handling.hasKey("sensitive"):
    doc.handling["sensitive"] = %false
  if not doc.handling.hasKey("pii"):
    doc.handling["pii"] = %false
  ensureObject(doc.lineage)
  ensureObject(doc.quality)
  ensureObject(doc.workflow)
  ensureObject(doc.geospatial)
  ensureObject(doc.data)
  ensureObject(doc.extensions)
  doc.ensureSchemaOrg

proc addSource*[T](doc: T, source: string) =
  doc.sources.add(source)

proc isEnvelopeKey(key: string): bool =
  key in [
    "dataset", "dtype", "schema_version", "version", "date_added", "date_updated",
    "title", "summary", "description", "status", "language", "tags", "labels",
    "aliases", "keywords", "identifiers", "evidence", "temporal", "provenance",
    "assessment", "verification", "handling", "lineage", "quality", "workflow",
    "geospatial", "attachments", "related_ids", "notes", "schema_org", "extensions"
  ]

proc structuredSources(values: seq[string]): JsonNode =
  result = newJArray()
  for source in values:
    result.add(%*{
      "kind": "web",
      "name": source,
      "uri": source,
      "url": source
    })

proc wireDataKey(key: string): string =
  case key
  of "fromF", "from_":
    return "from"
  of "resolved":
    return "resolved_addresses"
  else:
    discard

  for index, character in key:
    if character.isUpperAscii:
      if index > 0:
        result.add('_')
      result.add(character.toLowerAscii)
    else:
      result.add(character)

proc stringField(data: JsonNode, key: string): string =
  if data.kind == JObject and data.hasKey(key) and data[key].kind == JString:
    data[key].getStr
  else:
    ""

proc normalizeRequiredData(dtype: string, data: var JsonNode) =
  case dtype
  of "relation":
    if not data.hasKey("subject"):
      data["subject"] = %stringField(data, "source")
    if not data.hasKey("object"):
      data["object"] = %stringField(data, "target")
    if not data.hasKey("predicate") or stringField(data, "predicate").len == 0:
      data["predicate"] = %"related_to"
  of "domain":
    if not data.hasKey("domain"):
      data["domain"] = %stringField(data, "record")
  of "email":
    if not data.hasKey("address"):
      let user = stringField(data, "user")
      let domain = stringField(data, "domain")
      data["address"] = %(if user.len > 0 and domain.len > 0: user & "@" & domain else: "")
  of "email-message":
    if data.hasKey("to") and data["to"].kind == JString:
      let recipient = data["to"].getStr
      var recipients = newJArray()
      if recipient.len > 0:
        recipients.add(%recipient)
      data["to"] = recipients
    if data.hasKey("headers") and data["headers"].kind == JString:
      let raw = data["headers"].getStr
      var headers = newJObject()
      if raw.len > 0:
        headers["raw"] = %raw
      data["headers"] = headers
  else:
    discard

proc dump*[T](doc: T): JsonNode =
  ## Emit the canonical v0.9 wire object while preserving legacy subtype APIs.
  doc.setMeta(if doc.dataset.len > 0: doc.dataset else: "star-intel")
  let raw = %*doc
  result = newJObject()
  var subtypeData = if doc.data.isNil or doc.data.kind != JObject: newJObject() else: doc.data

  for key, value in raw.pairs:
    case key
    of "id":
      result["_id"] = value
    of "rev":
      if value.kind == JString and value.getStr.len > 0:
        result["_rev"] = value
    of "sources":
      result["sources"] = structuredSources(doc.sources)
    of "data":
      discard
    else:
      if isEnvelopeKey(key):
        result[key] = value
      else:
        subtypeData[wireDataKey(key)] = value

  normalizeRequiredData(doc.dtype, subtypeData)
  result["data"] = subtypeData

proc load*[T](node: JsonNode, t: typedesc[T]): T =
  ## Load canonical v0.9 JSON into the legacy-compatible Nim object hierarchy.
  var flattened = parseJson($node)
  if flattened.hasKey("_id"):
    flattened["id"] = flattened["_id"]
    flattened.delete("_id")
  if flattened.hasKey("_rev"):
    flattened["rev"] = flattened["_rev"]
    flattened.delete("_rev")
  if flattened.hasKey("sources") and flattened["sources"].kind == JArray:
    var legacySources = newJArray()
    for source in flattened["sources"].items:
      if source.kind == JString:
        legacySources.add(source)
      elif source.kind == JObject:
        if source.hasKey("url") and source["url"].kind == JString:
          legacySources.add(source["url"])
        elif source.hasKey("uri") and source["uri"].kind == JString:
          legacySources.add(source["uri"])
    flattened["sources"] = legacySources
  if flattened.hasKey("data") and flattened["data"].kind == JObject:
    for key, value in flattened["data"].pairs:
      flattened[key] = value
  result = flattened.to(t)
  result.setMeta(if result.dataset.len > 0: result.dataset else: "star-intel")

when isMainModule:
  var doc = Document()
  doc.setMeta()
  echo doc.dump
