import documents
type
  Relations* = enum
    to = 1
    origin = 2
    parent = 3
    child = 4
    between = 5
    member = 6

type BookerRelation* = ref object of BookerDocument
  ## A object that represents a relationship between two entities
  relation*: Relations
  ## The type of the relationship
  source*: string
  ## The ID of the source entity
  target*: string
  ## The ID of the target entity
proc newRelation*(source, target: string, relation: Relations, dataset: string): BookerRelation =
  ## Creates a new `BookerRelation` object with the specified `source`, `target`, and `relation` values
  ##
  ## Parameters:
  ##   source (string): The ID of the source entity
  ##   target (string): The ID of the target entity
  ##   relation (Relations): The type of the relationship
  ##
  ## Returns:
  ##   BookerRelation: The newly created `BookerRelation` object
  var doc = BookerRelation(source: source, target: target, relation: relation)
  doc.makeUUID
  doc.timeStamp()
  result = doc
