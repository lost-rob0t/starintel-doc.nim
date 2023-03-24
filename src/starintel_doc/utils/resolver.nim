# Return Dopcuments'children docs
# Possiblly make a type to hold related docs
import options, sequtils
import ../spec/spec


# Old code that will later be updated, for now ignore

type
  BookerChildrenDoc*[T] = ref object
    docs: seq[T]




proc resolve*[T, V](doc: T, dtype: V): BookerChildrenDoc =
  var childrenDocs: BookerChildrenDoc[dtype]
  childrendocs.concat(doc)
  result = childrenDocs
