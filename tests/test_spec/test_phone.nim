import ../../src/starintel_doc/phones

proc testPhone() =
  let pstr = "+12025832023"
  var phone = pstr.newPhone("verizon", "unknown", "cell")
  doAssert phone.phone == pstr
  doAssert phone.carrier == "verizon"
  doAssert phone.status == "unknown"
  doAssert phone.dtype == "phone"
  doAssert phone.phone_type == "cell"


when isMainModule:
  echo "testing: Phone"
  testPhone()
