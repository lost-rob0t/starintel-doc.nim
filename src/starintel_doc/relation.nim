import documents

type Relation* = ref object of Document
  ## A relationship between two StarIntel entities.
  source*: string
  target*: string
  predicate*: string
  note*: string

proc newRelation*(
  source, target: string,
  predicate: string = "related_to",
  note: string = "",
  dataset: string = "star-intel"
): Relation =
  ## Create a canonical relation while preserving the legacy source/target API.
  result = Relation(
    source: source,
    target: target,
    predicate: predicate,
    note: note,
    dataset: dataset,
    dtype: "relation"
  )
  result.makeUUID
  result.timestamp
  result.setMeta(dataset)
