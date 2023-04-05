import ../../src/starintel_doc/phones

proc testBookerPhone() =
  let pstr = "+12025832023"
  var phone = pstr.newPhone("verizon", "unknown", "cell")
  doAssert phone.phone == pstr
  doAssert phone.carrier == "verizon"
  doAssert phone.status == "unknown"
  doAssert phone.dtype == "phone"
  doAssert phone.phone_type == "cell"


when isMainModule:
  echo "testing: BookerPhone"
  testBookerPhone()
