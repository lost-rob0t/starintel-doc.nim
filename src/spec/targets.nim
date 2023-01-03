import json
import hashes
type
  BookerTarget = ref object of RootObj
    ## BookerTarget is an object that is used by actors (bots) to preform automations on documents
    ## Actors can find docs tagged with their name/id and load them and run their jobs
    ## Actor should be used as a bot id
    ## Options field may be used by the bot but SHOULD NOT be indexed into the database.
    id*: int
    rev*: string
    actor*: string
    dataset*: string
    target*: string
    options*: JsonNode

proc hash(x: BookerTarget): Hash =
  # NOTE Should options field be used in the hash?
  ## Hash a Target.
  ## ID field here instead of a uuid is a hash
  var h: Hash = 0
  h = h !& hash(x.actor)
  h = h !& hash(x.dataset)
  h = h !& hash(x.target)
  result = !$h

proc newTarget*(dataset, target, actor: string, options: JsonNode): BookerTarget =
  var doc = BookerTarget(dataset: dataset, target: target, actor: actor, options: options)
  doc.id = doc.hash
  result = doc

proc newTarget*(dataset, target, actor: string): BookerTarget =
  var doc = BookerTarget(dataset: dataset, target: target, actor: actor)
  doc.id = doc.hash
  result = doc
