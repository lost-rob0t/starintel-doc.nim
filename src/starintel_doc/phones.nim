import documents
type
  Phone* = ref object of Document
    ## A Phone number
    number*: string
    carrier*: string
    status*: string
    phone_type*: string


proc newPhone*(phone: string, carrier, status, phone_type = ""): Phone =
  Phone(number: phone, carrier: carrier, status: status, phone_type: phone_type,
      dtype: "phone")
