import documents
type Relation* = ref object of Document
  ## A object that represents a relationship between two entities
  source*: string
  ## The ID of the source entity
  target*: string
  ## The ID of the target entity
  note*: string
proc newRelation*(source, target: string, note: string = "", dataset: string): Relation =
  ## Creates a new `Relation` object with the specified `source`, `target`, and `note` values
  ##
  ## Parameters:
  ##   source (string): The ID of the source entity
  ##   target (string): The ID of the target entity
  ##   relation (Relations): The type of the relationship
  ##
  ## Returns:
  ##   Relation: The newly created `Relation` object
  var doc = Relation(source: source, target: target, note: note)
  doc.makeUUID
  doc.timeStamp()
  result = doc

