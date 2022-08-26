import documents
import options
type
  BookerGeo* = ref object of BookerDocument
    lat: Option[float64]
    long: Option[float64]
    gid: string

  BookerAddress* = ref object of BookerGeo
    city: string
    state: string
    postal: string
    country: string
    street: string
    street2: Option[string]
