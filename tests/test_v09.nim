import std/[json, unittest]
import starintel_doc

suite "StarIntel v0.9 Nim runtime":
  test "base document emits canonical envelope":
    var document = Document(dataset: "test", title: "Example")
    let wire = document.dump
    check wire["schema_version"].getStr == "0.9.0"
    check wire["version"].getInt == 1
    check wire["date_added"].getStr.len > 0
    check wire["schema_org"]["@context"].getStr == "https://schema.org/"
    check wire["schema_org"]["@id"].getStr == wire["_id"].getStr

  test "legacy org fields are nested under data":
    var org = newOrg("Example Org", "company")
    org.dataset = "test"
    org.country = "US"
    let wire = org.dump
    check wire["dtype"].getStr == "org"
    check wire["data"]["name"].getStr == "Example Org"
    check wire["data"]["etype"].getStr == "company"
    check wire["schema_org"]["@type"].getStr == "Organization"
    check not wire.hasKey("name")

  test "canonical document round trip restores subtype fields":
    var org = newOrg("Round Trip Org", "company")
    org.dataset = "test"
    org.reg = "123"
    let wire = org.dump
    let restored = load(wire, Org)
    check restored.name == "Round Trip Org"
    check restored.reg == "123"
    check restored.dataset == "test"
    check restored.schema_version == "0.9.0"

  test "required relation fields are promoted":
    let relation = newRelation(
      "starintel:person:ada",
      "starintel:org:analytical-engine",
      predicate = "worked_for",
      dataset = "test"
    )
    let wire = relation.dump
    check wire["data"]["subject"].getStr == "starintel:person:ada"
    check wire["data"]["object"].getStr == "starintel:org:analytical-engine"
    check wire["data"]["predicate"].getStr == "worked_for"

  test "domain and email required fields are promoted":
    var domain = newDomain("example.com", "A")
    domain.dataset = "test"
    let domainWire = domain.dump
    check domainWire["data"]["domain"].getStr == "example.com"
    check domainWire["data"]["record_type"].getStr == "A"

    var email = newEmail("ada", "example.com")
    email.dataset = "test"
    let emailWire = email.dump
    check emailWire["data"]["address"].getStr == "ada@example.com"

  test "Schema.org map covers every v0.9 dtype":
    check CanonicalDtypes.len == 49
    for dtype in CanonicalDtypes:
      check schemaOrgType(dtype).len > 0
