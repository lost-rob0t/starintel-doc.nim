# import documents, hosts
# import tables, sugar, sequtils
# import regex
# type
#   ScopeType* = enum
#     domain, cdir, mobileApp, url
#   Scope* = ref object of Document
#     ## Object Representing a pentest scope.
#     ## The name of the program is used to set the "dataset" field of the metadata doc.
#     description*: string
#     outscope*: seq[string]
#     inscope*: seq[string]
#     scopeType*: ScopeType


# const DOMAIN_REGEX = re"^(?:[a-z0-9_](?:[a-z0-9-_]{0,61}[a-z0-9])?\\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$"
# proc newScope*(name, description: string, scopeType: ScopeType = ScopeType.domain): Scope =
#   var doc = Scope(dataset: name, description: description, scopeType: scopeType)
#   doc.timestamp
#   doc.setType
#   result = doc


# proc inScopeAdd*(scope: Scope, item: string) =
#   ## Add a Item to the Scope object's scope.
#   scope.inscope.add(item)

# proc inScopeAdd*(scope: Scope, items: seq[string]) =
#   ## Add a Sequence to the Scope object's inscope.
#   scope.inscope =  scope.inscope.concat(items)

# proc outScopeAdd*(scope: Scope, item: string) =
#   ## Add a Item to the Scope objects's outscope.
#   scope.outscope.add(item)

# proc outScopeAdd*(scope: Scope, items: seq[string]) =
#   ## Add a Sequence to the Scope object's outscope.
#   scope.outscope = scope.outscope.concat(items)


# proc domainInscope*(item: string, scope: Scope): bool =
#   ## A test function to see if a domain is in scope.
#   ## You can use this as an example to implement CDIR scopes.
#   ## It just needs to take the input string and the Table.

#   # BUG i need to throw error....
#   if scope.scopeType != ScopeType.domain: discard
#   for regex in scope.outscope:
#       if item.contains(re(regex)):
#         return false
#   for regex in scope.inscope:
#       if item.contains(re(regex)):
#         return true




# proc contains*(scope: Scope, item: string, testFun: (item: string, scope: Scope) -> bool = domainInScope): bool =
#   ## Test if a item is is inscope using `testFun`. By default it uses `domainInscope` as the test fn
#   result = testFun(item, scope)

# proc contains*(scope: Scope, item: Domain , testFun: (item: string, scope: Scope) -> bool = domainInScope): bool =
#   ## Test if a item is is inscope using `testFun`. By default it uses `domainInscope` as the test fn
#   result = testFun(item.record, scope)



# when isMainModule:
#   import json, strformat
#   var scope = newScope("hackerOne", "Hackerone is a bug bounty pplatform")
#   scope.inScopeAdd(".*.hackerone.com")
#   scope.outScopeAdd("mail.hackerone.com")
#   echo %*scope
#   if contains(scope, "test.hackerone.com"):
#     echo "Test is in scope!"
#     echo contains(scope, "test.hackerone.com")
#   echo "mail was not in scope! true/false?"
#   echo contains(scope, "mail.hackerone.com")

#   echo "testing domain object"
#   var domain = newDomain("foo.hackerone.com", "A", "", "subfinder")
#   var domain2 = newDomain("mail.hackerone.com", "A", "", "subfinder")
#   echo fmt"domain: {domain.record} inscope?: {scope.contains(domain)}"
#   echo fmt"domain: {domain2.record} inscope?: {scope.contains(domain2)}"
