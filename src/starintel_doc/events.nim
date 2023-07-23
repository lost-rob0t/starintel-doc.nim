import locations, documents


type
  Event* = ref object of Document
    ## Expirmental object to represent an event in the real world
    eventName*: string
    eventType*: string
    location*: Address
