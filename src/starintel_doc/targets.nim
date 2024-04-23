import json
import documents, scope
type
  Target* = ref object of RootObj
    ## Target is an object that is used by actors (bots) to preform automations on documents
    ## Actors can find docs tagged with their name/id and load them and run their jobs
    ## Actor should be used as a bot id
    ## Options field may be used by the bot but SHOULD NOT be indexed into the database.
    id*: string
    version*: string = DOC_VERSION
    actor*: string
    dataset*: string
    target*: string
    delay*: int64
    recurring*: bool
    options*: JsonNode

  # ScanInput* = ref object
  #   ## This Object Bundles the target type and the scope object.
  #   ## This should be used for any tool that "scans" and must respect some sort of scope.
  #   id*: string
  #   target*: Target
  #   scope*: Scope

proc newTarget*(dataset, target, actor: string, delay: int = 0, recurring: bool = false, options: JsonNode): Target =
  var doc = Target(dataset: dataset, target: target, actor: actor,
                   options: options, recurring: recurring, delay: delay)
  doc.makeMD5ID(dataset & target & actor & $recurring & $delay)
  result = doc


# proc newScan*(dataset, target, actor: string, scope: Scope): ScanInput =
#   var doc = ScanInput(target: newTarget(dataset, target, actor), scope: scope)
#   doc.makeMD5ID(dataset & target & actor)
#   result = doc
