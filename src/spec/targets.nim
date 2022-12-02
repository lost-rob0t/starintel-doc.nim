import json
type
  BookerTarget = ref object of RootObj
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
  BookerTarget(dataset: dataset, target: target, actor: actor, options: options)


proc newTarget*(dataset, target, actor: string): BookerTarget =
  BookerTarget(dataset: dataset, target: target, actor: actor)
