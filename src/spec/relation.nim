import documents
type
  Relations* = enum
    to = 1
    origin = 2
    parent = 3
    child = 4
    between = 5
    member = 6
  BookerRelation* = ref object
    id*: string
    rev*: string
    relation*: Relations
    source*: string
    target*: string


proc newRelation*(source, target: string, relation: Relations): BookerRelation =
  var doc = BookerRelation(source: source, target: target, relation: relation)
  doc.makeUUID
  result = doc
