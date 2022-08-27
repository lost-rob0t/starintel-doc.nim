import documents
import options
type
  BookerPhone* = ref object of BookerDocument
      ## A Phone number
      phone*: string
      carrier*: Option[string]
      status*: Option[string]
      phone_type*: Option[string]


proc newPhone*(phone: string, carrier, status, phone_type = none(string)): BookerPhone =
  BookerPhone(phone: phone, carrier: carrier, status: status, phone_type: phone_type)
