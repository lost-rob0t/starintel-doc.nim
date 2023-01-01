import ../src/starintel_doc
import json, jsony

proc testRemap() =
  let config = %* {
        "fname": "first-name",
        "lname": "last-name",
        "phones": "tele",
        "emails": "e"

    }
  let jsonString = """{"last-name":"Jacobson","first-name":"Marilyn","tele":["107-424-2910","503-733-1119","822-083-3531"],"e":["Marilyn74@hotmail.com"]}"""
  let j = jsonString.parseJson().remap(config)
  assert j == %*{"fname":"Marilyn","lname":"Jacobson","phones":["107-424-2910","503-733-1119","822-083-3531"],"emails":["Marilyn74@hotmail.com"]}

proc testInject() =
  let config = %* {
        "fname": "first-name",
        "lname": "last-name",
        "phones": "tele",
        "emails": "e"

    }
  let inject = %*{"test": "test"}
  let jsonString = """{"last-name":"Jacobson","first-name":"Marilyn","tele":["107-424-2910","503-733-1119","822-083-3531"],"e":["Marilyn74@hotmail.com"]}"""
  let j = jsonString.parseJson().remapInject(config, inject)

  assert j == %*{"fname":"Marilyn","lname":"Jacobson","phones":["107-424-2910","503-733-1119","822-083-3531"],"emails":["Marilyn74@hotmail.com"], "test": "test"}

echo "Testing remap"
testRemap()
echo "test remapInject"
testInject()
