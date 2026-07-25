import std/[json, strutils]

const SchemaOrgContext* = "https://schema.org/"

const CanonicalDtypes* = [
  "actor-manifest", "address", "alert", "analysis", "asset", "breach",
  "campaign-finance", "claim", "concept", "contract", "dataset-manifest",
  "document", "domain", "education", "email", "email-message", "employment",
  "entity", "event", "evidence-record", "file", "financial-observation", "geo",
  "grant", "host", "investigation-target", "legal-case", "lobbying-filing",
  "location", "media", "meeting", "message", "network", "observation", "org",
  "ownership", "person", "phone", "policy", "procurement", "product", "relation",
  "research-pass", "social-media-post", "source", "target", "task", "url", "user"
]

proc canonicalDtype*(dtype: string): string =
  let key = dtype.strip.toLowerAscii.replace("_", "-").replace(" ", "-")
  case key
  of "organization", "organisation": "org"
  of "geolocation", "geographic-location": "geo"
  of "email-address", "electronic-mail": "email"
  of "emailmessage": "email-message"
  of "hostname": "host"
  of "phone-number", "telephone", "telephone-number": "phone"
  of "uniform-resource-locator", "web-url": "url"
  of "socialmpost", "socialmediapost": "social-media-post"
  of "investigationtarget": "investigation-target"
  of "researchpass": "research-pass"
  of "datasetmanifest": "dataset-manifest"
  of "actormanifest": "actor-manifest"
  of "legalcase": "legal-case"
  of "lobbyingfiling": "lobbying-filing"
  of "campaignfinance": "campaign-finance"
  of "financialobservation": "financial-observation"
  of "evidencerecord": "evidence-record"
  else: key

proc schemaOrgType*(dtype: string): string =
  case canonicalDtype(dtype)
  of "actor-manifest": "CreativeWork"
  of "address": "PostalAddress"
  of "alert": "SpecialAnnouncement"
  of "analysis": "CreativeWork"
  of "asset": "Thing"
  of "breach": "Event"
  of "campaign-finance": "CreativeWork"
  of "claim": "Claim"
  of "concept": "DefinedTerm"
  of "contract": "DigitalDocument"
  of "dataset-manifest": "Dataset"
  of "document": "CreativeWork"
  of "domain": "WebSite"
  of "education": "EducationalOccupationalCredential"
  of "email": "ContactPoint"
  of "email-message": "Message"
  of "employment": "OrganizationRole"
  of "entity": "Thing"
  of "event": "Event"
  of "evidence-record": "CreativeWork"
  of "file": "DigitalDocument"
  of "financial-observation": "CreativeWork"
  of "geo": "GeoCoordinates"
  of "grant": "Grant"
  of "host": "Thing"
  of "investigation-target": "Thing"
  of "legal-case": "CreativeWork"
  of "lobbying-filing": "DigitalDocument"
  of "location": "Place"
  of "media": "MediaObject"
  of "meeting": "Event"
  of "message": "Message"
  of "network": "Thing"
  of "observation": "CreativeWork"
  of "org": "Organization"
  of "ownership": "Role"
  of "person": "Person"
  of "phone": "ContactPoint"
  of "policy": "CreativeWork"
  of "procurement": "DigitalDocument"
  of "product": "Product"
  of "relation": "Role"
  of "research-pass": "CreativeWork"
  of "social-media-post": "SocialMediaPosting"
  of "source": "CreativeWork"
  of "target": "Thing"
  of "task": "Action"
  of "url": "WebPage"
  of "user": "Person"
  else: "Thing"

proc schemaOrgMetadata*(dtype: string, documentId = ""): JsonNode =
  let canonical = canonicalDtype(dtype)
  result = %*{
    "@context": SchemaOrgContext,
    "@type": schemaOrgType(canonical),
    "additionalType": "https://starintel.dev/dtype/" & canonical
  }
  if documentId.len > 0:
    result["@id"] = %documentId

proc stringValue(node: JsonNode, key: string): string =
  if node.kind == JObject and node.hasKey(key) and node[key].kind == JString:
    node[key].getStr
  else:
    ""

proc toSchemaOrg*(document: JsonNode): JsonNode =
  let dtype = stringValue(document, "dtype")
  let documentId = stringValue(document, "_id")
  result = schemaOrgMetadata(dtype, documentId)
  let data = if document.kind == JObject and document.hasKey("data") and document["data"].kind == JObject:
      document["data"]
    else:
      newJObject()

  var name = stringValue(document, "title")
  if name.len == 0:
    for key in ["display_name", "full_name", "legal_name", "name", "claim", "term", "target"]:
      name = stringValue(data, key)
      if name.len > 0: break
  if name.len == 0: name = documentId
  result["name"] = %name

  var description = stringValue(document, "description")
  if description.len == 0: description = stringValue(document, "summary")
  if description.len == 0: description = stringValue(data, "description")
  if description.len > 0: result["description"] = %description

  let language = stringValue(document, "language")
  if language.len > 0: result["inLanguage"] = %language
  let dateAdded = stringValue(document, "date_added")
  if dateAdded.len > 0: result["dateCreated"] = %dateAdded
  let dateUpdated = stringValue(document, "date_updated")
  if dateUpdated.len > 0: result["dateModified"] = %dateUpdated

  var url = stringValue(data, "url")
  if url.len == 0: url = stringValue(data, "website")
  if url.len == 0: url = stringValue(data, "uri")
  if url.len > 0: result["url"] = %url

  if document.kind == JObject and document.hasKey("schema_org") and document["schema_org"].kind == JObject:
    for key, value in document["schema_org"].pairs:
      result[key] = value

static:
  doAssert CanonicalDtypes.len == 49
  for dtype in CanonicalDtypes:
    doAssert schemaOrgType(dtype) != ""
