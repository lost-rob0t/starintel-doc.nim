import json
import documents
type
  BookerTarget* = ref object of RootObj
    ## BookerTarget is an object that is used by actors (bots) to preform automations on documents
    ## Actors can find docs tagged with their name/id and load them and run their jobs
    ## Actor should be used as a bot id
    ## Options field may be used by the bot but SHOULD NOT be indexed into the database.
    id*: string
    rev*: string
    actor*: string
    dataset*: string
    target*: string
    options*: JsonNode

proc newTarget*(dataset, target, actor: string, options: JsonNode): BookerTarget =
  var doc = BookerTarget(dataset: dataset, target: target, actor: actor, options: options)
  doc.makeMD5ID(dataset & target & actor)
  result = doc

proc newTarget*(dataset, target, actor: string): BookerTarget =
  var doc = BookerTarget(dataset: dataset, target: target, actor: actor)
  doc.makeMD5ID(dataset & target & actor)
  result = doc
