import documents
import options
import strutils
type
  Geo* = ref object of Document
    lat*: float64
    long*: float64
    alt*: float64

  Address* = ref object of Geo
    city*: string
    state*: string
    postal*: string
    country*: string
    street*: string
    street2*: string

proc newAddress*(street, street2, city, postal, state, country: string, lat,
    long = 0.0): Address =
  var doc = Address(street: street, street2: street2, city: city,
      postal: postal, state: state, country: country, lat: lat, long: long)
  doc.makeMD5ID(street & street2 & city & state & country & postal)
  result = doc
