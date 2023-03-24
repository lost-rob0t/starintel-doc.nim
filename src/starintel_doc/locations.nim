import documents
import options
import strutils
type
  BookerGeo* = ref object of RootObj
    lat*: float64
    long*: float64
    alt*: float64
    gid*: string

  BookerAddress* = ref object of BookerGeo
    city*: string
    state*: string
    postal*: string
    country*: string
    street*: string
    street2*: string

proc newAddress*(street, street2, city, postal, state, country: string, lat, long = 0.0): BookerAddress =
  var doc = BookerAddress(street: street, street2: street2, city: city, postal: postal, state: state, country: country, lat: lat, long: long)
  doc.gid = makeHash(street & street2 & city & state & country & postal)
  result = doc
