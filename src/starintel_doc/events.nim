import locations, documents


type
  BookerEvent* = ref object of BookerDocument
    ## Expirmental object to represent an event in the real world
    eventName*: string
    eventType*: string
    location*: BookerAddress
