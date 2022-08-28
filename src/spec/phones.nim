import documents
type
  BookerPhone* = ref object of BookerDocument
      ## A Phone number
      phone*: string
      carrier*: string
      status*: string
      phone_type*: string


proc newPhone*(phone: string, carrier, status, phone_type = ""): BookerPhone =
  BookerPhone(phone: phone, carrier: carrier, status: status, phone_type: phone_type)
